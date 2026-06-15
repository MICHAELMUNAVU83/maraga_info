defmodule MaragaInfo.Campaigns.EmailDelivery do
  @moduledoc """
  One recipient row for an `EmailCampaign`. Each delivery is sent by its own
  Oban job so that a single bad address never blocks the rest of the blast.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending sent failed)

  schema "email_deliveries" do
    field :email, :string
    field :name, :string
    field :status, :string, default: "pending"
    field :error, :string
    field :sent_at, :utc_datetime

    belongs_to :campaign, MaragaInfo.Campaigns.EmailCampaign

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [:campaign_id, :email, :name, :status, :error, :sent_at])
    |> validate_required([:campaign_id, :email, :status])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint([:campaign_id, :email],
      name: :email_deliveries_campaign_id_email_index
    )
  end

  def statuses, do: @statuses
end
