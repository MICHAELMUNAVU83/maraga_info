defmodule MaragaInfo.Campaigns do
  @moduledoc """
  The Campaigns context: designing email blasts and sending them to the
  volunteer database reliably through Oban.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias MaragaInfo.Campaigns.CampaignEmail
  alias MaragaInfo.Campaigns.DeliveryWorker
  alias MaragaInfo.Campaigns.EmailCampaign
  alias MaragaInfo.Campaigns.EmailDelivery
  alias MaragaInfo.Mailer
  alias MaragaInfo.Repo
  alias MaragaInfo.Volunteers.Volunteer

  ## Campaigns

  def list_campaigns do
    EmailCampaign
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
  end

  def get_campaign!(id), do: Repo.get!(EmailCampaign, id)

  def change_campaign(%EmailCampaign{} = campaign, attrs \\ %{}) do
    EmailCampaign.changeset(campaign, attrs)
  end

  def create_campaign(attrs \\ %{}) do
    %EmailCampaign{}
    |> EmailCampaign.changeset(attrs)
    |> Repo.insert()
  end

  def update_campaign(%EmailCampaign{status: "draft"} = campaign, attrs) do
    campaign
    |> EmailCampaign.changeset(attrs)
    |> Repo.update()
  end

  def update_campaign(%EmailCampaign{}, _attrs), do: {:error, :not_editable}

  def delete_campaign(%EmailCampaign{} = campaign), do: Repo.delete(campaign)

  ## Recipients (the volunteer database)

  @doc "Volunteers with a usable email address, as `%{email:, name:}` maps."
  def recipient_pool do
    Volunteer
    |> where([v], not is_nil(v.email) and v.email != "")
    |> select([v], %{email: v.email, name: v.full_name})
    |> Repo.all()
  end

  def recipient_count do
    Volunteer
    |> where([v], not is_nil(v.email) and v.email != "")
    |> Repo.aggregate(:count, :id)
  end

  ## Sending

  @doc """
  Queues a draft campaign for delivery: snapshots the recipient list into
  `email_deliveries` and enqueues one Oban job per recipient.
  """
  def send_campaign(%EmailCampaign{status: "draft"} = campaign) do
    recipients = recipient_pool()
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    rows =
      Enum.map(recipients, fn r ->
        %{
          campaign_id: campaign.id,
          email: r.email,
          name: r.name,
          status: "pending",
          inserted_at: now,
          updated_at: now
        }
      end)

    if rows == [] do
      {:error, :no_recipients}
    else
      Multi.new()
      |> Multi.insert_all(:deliveries, EmailDelivery, rows, returning: [:id])
      |> Multi.update(
        :campaign,
        EmailCampaign.changeset(campaign, %{})
        |> Ecto.Changeset.force_change(:status, "sending")
        |> Ecto.Changeset.put_change(:recipient_count, length(rows))
        |> Ecto.Changeset.put_change(:sent_count, 0)
        |> Ecto.Changeset.put_change(:failed_count, 0)
      )
      |> Multi.run(:jobs, fn _repo, %{deliveries: {_count, deliveries}} ->
        jobs = Enum.map(deliveries, &DeliveryWorker.new(%{delivery_id: &1.id}))
        {:ok, Oban.insert_all(jobs)}
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{campaign: campaign}} -> {:ok, campaign}
        {:error, _step, reason, _changes} -> {:error, reason}
      end
    end
  end

  def send_campaign(%EmailCampaign{}), do: {:error, :already_sent}

  @doc "Sends a single preview/test email immediately (bypasses Oban)."
  def send_test_email(%EmailCampaign{} = campaign, email) when is_binary(email) do
    campaign
    |> CampaignEmail.build(%{email: email, name: "Friend"}, from())
    |> Mailer.deliver()
  end

  @doc """
  Delivers one queued recipient. Called by `DeliveryWorker`. Returns `:ok` or
  `{:error, reason}` so Oban can retry; only marks the row failed on the last
  attempt.
  """
  def deliver(delivery_id, opts \\ []) do
    delivery = Repo.get!(EmailDelivery, delivery_id) |> Repo.preload(:campaign)

    if delivery.status == "sent" do
      :ok
    else
      email =
        CampaignEmail.build(
          delivery.campaign,
          %{email: delivery.email, name: delivery.name},
          from()
        )

      case Mailer.deliver(email) do
        {:ok, _meta} ->
          mark_delivery(delivery, %{status: "sent", error: nil, sent_at: now()})
          finalize_if_complete(delivery.campaign_id)
          :ok

        {:error, reason} ->
          if Keyword.get(opts, :last_attempt?, true) do
            mark_delivery(delivery, %{status: "failed", error: inspect_reason(reason)})
            finalize_if_complete(delivery.campaign_id)
          end

          {:error, reason}
      end
    end
  end

  ## Progress helpers

  @doc "Live counts for a campaign's deliveries."
  def delivery_stats(campaign_id) do
    rows =
      EmailDelivery
      |> where([d], d.campaign_id == ^campaign_id)
      |> group_by([d], d.status)
      |> select([d], {d.status, count(d.id)})
      |> Repo.all()
      |> Map.new()

    sent = Map.get(rows, "sent", 0)
    failed = Map.get(rows, "failed", 0)
    pending = Map.get(rows, "pending", 0)

    %{sent: sent, failed: failed, pending: pending, total: sent + failed + pending}
  end

  ## Internal

  defp mark_delivery(%EmailDelivery{} = delivery, attrs) do
    delivery
    |> EmailDelivery.changeset(attrs)
    |> Repo.update()
  end

  # When no deliveries are left pending, stamp the campaign as sent and store
  # the final tallies. Whichever worker observes the empty queue wins the race.
  defp finalize_if_complete(campaign_id) do
    stats = delivery_stats(campaign_id)

    if stats.pending == 0 do
      EmailCampaign
      |> where([c], c.id == ^campaign_id and c.status != "sent")
      |> Repo.update_all(
        set: [
          status: "sent",
          sent_count: stats.sent,
          failed_count: stats.failed,
          sent_at: now(),
          updated_at: now()
        ]
      )
    else
      :ok
    end
  end

  defp from, do: Application.fetch_env!(:maraga_info, :mail_from)

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp inspect_reason(reason) when is_binary(reason), do: String.slice(reason, 0, 250)
  defp inspect_reason(reason), do: reason |> inspect() |> String.slice(0, 250)
end
