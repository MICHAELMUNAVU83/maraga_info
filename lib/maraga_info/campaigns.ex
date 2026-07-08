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
  alias MaragaInfo.Campaigns.SmsCampaign
  alias MaragaInfo.Campaigns.SmsDelivery
  alias MaragaInfo.Campaigns.SmsDeliveryWorker
  alias MaragaInfo.Mailer
  alias MaragaInfo.Repo
  alias MaragaInfo.Sasasignal
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

  ## SMS campaigns

  def list_sms_campaigns do
    SmsCampaign
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
  end

  def get_sms_campaign!(id), do: Repo.get!(SmsCampaign, id)

  def change_sms_campaign(%SmsCampaign{} = campaign, attrs \\ %{}) do
    SmsCampaign.changeset(campaign, attrs)
  end

  def create_sms_campaign(attrs \\ %{}) do
    %SmsCampaign{}
    |> SmsCampaign.changeset(attrs)
    |> Repo.insert()
  end

  def update_sms_campaign(%SmsCampaign{status: "draft"} = campaign, attrs) do
    campaign
    |> SmsCampaign.changeset(attrs)
    |> Repo.update()
  end

  def update_sms_campaign(%SmsCampaign{}, _attrs), do: {:error, :not_editable}

  def delete_sms_campaign(%SmsCampaign{} = campaign), do: Repo.delete(campaign)

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

  @doc "Volunteers with a usable phone number, as `%{phone:, name:}` maps."
  def sms_recipient_pool do
    Volunteer
    |> where([v], not is_nil(v.phone) and v.phone != "")
    |> select([v], %{phone: v.phone, name: v.full_name})
    |> Repo.all()
  end

  def sms_recipient_count do
    Volunteer
    |> where([v], not is_nil(v.phone) and v.phone != "")
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
      recipients
      |> Enum.with_index()
      |> Enum.map(fn {r, index} ->
        %{
          campaign_id: campaign.id,
          email: r.email,
          name: r.name,
          variant: assign_variant(campaign, index),
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

  @doc """
  Queues a draft SMS campaign for delivery. Each recipient is processed by its
  own Oban job so retries back off independently.
  """
  def send_sms_campaign(%SmsCampaign{status: "draft"} = campaign) do
    recipients = sms_recipient_pool()
    now = now()

    rows =
      Enum.map(recipients, fn recipient ->
        %{
          campaign_id: campaign.id,
          phone: recipient.phone,
          name: recipient.name,
          status: "pending",
          inserted_at: now,
          updated_at: now
        }
      end)

    if rows == [] do
      {:error, :no_recipients}
    else
      Multi.new()
      |> Multi.insert_all(:deliveries, SmsDelivery, rows, returning: [:id])
      |> Multi.update(
        :campaign,
        SmsCampaign.changeset(campaign, %{})
        |> Ecto.Changeset.force_change(:status, "sending")
        |> Ecto.Changeset.put_change(:recipient_count, length(rows))
        |> Ecto.Changeset.put_change(:sent_count, 0)
        |> Ecto.Changeset.put_change(:failed_count, 0)
      )
      |> Multi.run(:jobs, fn _repo, %{deliveries: {_count, deliveries}} ->
        jobs = Enum.map(deliveries, &SmsDeliveryWorker.new(%{delivery_id: &1.id}))
        {:ok, Oban.insert_all(jobs)}
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{campaign: campaign}} -> {:ok, campaign}
        {:error, _step, reason, _changes} -> {:error, reason}
      end
    end
  end

  def send_sms_campaign(%SmsCampaign{}), do: {:error, :already_sent}

  # Even split: alternating recipients go to B when A/B testing is on, so the
  # pool is divided ~50/50 between the two variants. Without A/B everyone gets A.
  defp assign_variant(%EmailCampaign{ab_test: true}, index) when rem(index, 2) == 1, do: "B"
  defp assign_variant(_campaign, _index), do: "A"

  @doc """
  Sends a single preview/test email immediately (bypasses Oban). `variant`
  selects which version (`"A"` or `"B"`) to send; defaults to `"A"`.
  """
  def send_test_email(%EmailCampaign{} = campaign, email, variant \\ "A", first_name \\ "Friend")
      when is_binary(email) and is_binary(first_name) do
    campaign
    |> CampaignEmail.build(
      variant,
      %{email: email, name: test_recipient_name(first_name)},
      from_address()
    )
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
          delivery.variant,
          %{email: delivery.email, name: delivery.name},
          from_address()
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

  @doc """
  Sends a single preview/test SMS immediately.
  """
  def send_test_sms(%SmsCampaign{} = campaign, phone, first_name \\ "Friend")
      when is_binary(phone) and is_binary(first_name) do
    message =
      campaign.message
      |> personalize_sms(%{name: test_recipient_name(first_name)})

    Sasasignal.send_individual_sms(
      message,
      phone,
      sender_id: campaign.sender_id,
      callback_url: campaign.callback_url
    )
  end

  @doc """
  Delivers one queued SMS recipient. Called by `SmsDeliveryWorker`.
  """
  def deliver_sms(delivery_id, opts \\ []) do
    delivery = Repo.get!(SmsDelivery, delivery_id) |> Repo.preload(:campaign)

    if delivery.status == "sent" do
      :ok
    else
      message =
        delivery.campaign.message
        |> personalize_sms(%{name: delivery.name})

      case Sasasignal.send_individual_sms(
             message,
             delivery.phone,
             sender_id: delivery.campaign.sender_id,
             callback_url: delivery.campaign.callback_url
           ) do
        {:ok, response} ->
          mark_sms_delivery(delivery, %{
            status: "sent",
            error: nil,
            provider_response: inspect_provider_response(response),
            sent_at: now()
          })

          finalize_sms_if_complete(delivery.campaign_id)
          :ok

        {:error, reason} ->
          if Keyword.get(opts, :last_attempt?, true) do
            mark_sms_delivery(delivery, %{
              status: "failed",
              error: inspect_reason(reason),
              provider_response: inspect_provider_response(reason)
            })

            finalize_sms_if_complete(delivery.campaign_id)
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

  @doc """
  Lists delivery rows for a campaign with optional search and filters.
  """
  def list_deliveries(campaign_id, opts \\ []) do
    campaign_id
    |> deliveries_query(opts)
    |> limit(^Keyword.get(opts, :limit, 25))
    |> offset(^Keyword.get(opts, :offset, 0))
    |> Repo.all()
  end

  @doc """
  Counts delivery rows for a campaign after optional search and filters.
  """
  def count_deliveries(campaign_id, opts \\ []) do
    campaign_id
    |> deliveries_query(opts)
    |> exclude(:order_by)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  High-level delivery timing summary for a campaign.
  """
  def delivery_overview(campaign_id) do
    Repo.one(
      from d in EmailDelivery,
        where: d.campaign_id == ^campaign_id,
        select: %{
          first_sent_at: min(d.sent_at),
          last_sent_at: max(d.sent_at),
          last_updated_at: max(d.updated_at)
        }
    )
  end

  @doc """
  Per-variant delivery counts for an A/B campaign, as `%{"A" => stats, "B" =>
  stats}`. Variants with no deliveries are omitted.
  """
  def variant_stats(campaign_id) do
    EmailDelivery
    |> where([d], d.campaign_id == ^campaign_id)
    |> group_by([d], [d.variant, d.status])
    |> select([d], {d.variant, d.status, count(d.id)})
    |> Repo.all()
    |> Enum.group_by(fn {variant, _status, _count} -> variant end)
    |> Map.new(fn {variant, rows} ->
      counts = Map.new(rows, fn {_v, status, count} -> {status, count} end)
      sent = Map.get(counts, "sent", 0)
      failed = Map.get(counts, "failed", 0)
      pending = Map.get(counts, "pending", 0)

      {variant, %{sent: sent, failed: failed, pending: pending, total: sent + failed + pending}}
    end)
  end

  ## SMS progress helpers

  def sms_delivery_stats(campaign_id) do
    rows =
      SmsDelivery
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

  def list_sms_deliveries(campaign_id, opts \\ []) do
    campaign_id
    |> sms_deliveries_query(opts)
    |> limit(^Keyword.get(opts, :limit, 25))
    |> offset(^Keyword.get(opts, :offset, 0))
    |> Repo.all()
  end

  def count_sms_deliveries(campaign_id, opts \\ []) do
    campaign_id
    |> sms_deliveries_query(opts)
    |> exclude(:order_by)
    |> Repo.aggregate(:count, :id)
  end

  def sms_delivery_overview(campaign_id) do
    Repo.one(
      from d in SmsDelivery,
        where: d.campaign_id == ^campaign_id,
        select: %{
          first_sent_at: min(d.sent_at),
          last_sent_at: max(d.sent_at),
          last_updated_at: max(d.updated_at)
        }
    )
  end

  ## Internal

  defp mark_delivery(%EmailDelivery{} = delivery, attrs) do
    delivery
    |> EmailDelivery.changeset(attrs)
    |> Repo.update()
  end

  defp mark_sms_delivery(%SmsDelivery{} = delivery, attrs) do
    delivery
    |> SmsDelivery.changeset(attrs)
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

  defp finalize_sms_if_complete(campaign_id) do
    stats = sms_delivery_stats(campaign_id)

    if stats.pending == 0 do
      SmsCampaign
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

  # The configured sending address. Each variant supplies its own display name,
  # so we only need the email here.
  defp from_address do
    case Application.fetch_env!(:maraga_info, :mail_from) do
      {_name, email} -> email
      email when is_binary(email) -> email
    end
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp inspect_reason(reason) when is_binary(reason), do: String.slice(reason, 0, 250)
  defp inspect_reason(reason), do: reason |> inspect() |> String.slice(0, 250)

  defp inspect_provider_response(nil), do: nil
  defp inspect_provider_response(%{body: body}), do: inspect_provider_response(body)
  defp inspect_provider_response(value) when is_binary(value), do: String.slice(value, 0, 500)
  defp inspect_provider_response(value), do: value |> inspect() |> String.slice(0, 500)

  defp test_recipient_name(first_name) do
    case String.trim(first_name) do
      "" -> "Friend"
      trimmed -> trimmed
    end
  end

  defp personalize_sms(message, recipient) do
    name = Map.get(recipient, :name) || Map.get(recipient, "name") || ""
    first_name = first_name_from_name(name)

    message
    |> String.replace("{{name}}", if(name == "", do: "Friend", else: name))
    |> String.replace("{{first_name}}", first_name)
  end

  defp first_name_from_name(name) when is_binary(name) do
    case name |> String.trim() |> String.split(~r/\s+/, trim: true) do
      [first | _] -> first
      _ -> "Friend"
    end
  end

  defp first_name_from_name(_name), do: "Friend"

  defp deliveries_query(campaign_id, opts) do
    EmailDelivery
    |> where([d], d.campaign_id == ^campaign_id)
    |> maybe_filter_delivery_query(Keyword.get(opts, :query, ""))
    |> maybe_filter_delivery_status(Keyword.get(opts, :status, "all"))
    |> maybe_filter_delivery_variant(Keyword.get(opts, :variant, "all"))
    |> order_by([d], desc: d.updated_at, desc: d.id)
  end

  defp maybe_filter_delivery_query(query, value) do
    trimmed = value |> to_string() |> String.trim()

    if trimmed == "" do
      query
    else
      pattern = "%#{trimmed}%"

      where(
        query,
        [d],
        ilike(d.email, ^pattern) or ilike(coalesce(d.name, ""), ^pattern) or
          ilike(coalesce(d.error, ""), ^pattern)
      )
    end
  end

  defp maybe_filter_delivery_status(query, status) when status in ~w(pending sent failed),
    do: where(query, [d], d.status == ^status)

  defp maybe_filter_delivery_status(query, _status), do: query

  defp maybe_filter_delivery_variant(query, variant) when variant in ~w(A B),
    do: where(query, [d], d.variant == ^variant)

  defp maybe_filter_delivery_variant(query, _variant), do: query

  defp sms_deliveries_query(campaign_id, opts) do
    SmsDelivery
    |> where([d], d.campaign_id == ^campaign_id)
    |> maybe_filter_sms_delivery_query(Keyword.get(opts, :query, ""))
    |> maybe_filter_sms_delivery_status(Keyword.get(opts, :status, "all"))
    |> order_by([d], desc: d.updated_at, desc: d.id)
  end

  defp maybe_filter_sms_delivery_query(query, value) do
    trimmed = value |> to_string() |> String.trim()

    if trimmed == "" do
      query
    else
      pattern = "%#{trimmed}%"

      where(
        query,
        [d],
        ilike(d.phone, ^pattern) or ilike(coalesce(d.name, ""), ^pattern) or
          ilike(coalesce(d.error, ""), ^pattern) or
          ilike(coalesce(d.provider_response, ""), ^pattern)
      )
    end
  end

  defp maybe_filter_sms_delivery_status(query, status) when status in ~w(pending sent failed),
    do: where(query, [d], d.status == ^status)

  defp maybe_filter_sms_delivery_status(query, _status), do: query
end
