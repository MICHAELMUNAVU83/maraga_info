defmodule MaragaInfo.Campaigns.SmsDelivery do
  @moduledoc """
  One queued SMS recipient row for an `SmsCampaign`.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending sent failed)

  schema "sms_deliveries" do
    field :phone, :string
    field :name, :string
    field :status, :string, default: "pending"
    field :error, :string
    field :provider_response, :string
    field :sent_at, :utc_datetime

    belongs_to :campaign, MaragaInfo.Campaigns.SmsCampaign

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [:campaign_id, :phone, :name, :status, :error, :provider_response, :sent_at])
    |> validate_required([:campaign_id, :phone, :status])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint([:campaign_id, :phone],
      name: :sms_deliveries_campaign_id_phone_index
    )
  end

  def statuses, do: @statuses
end
