defmodule MaragaInfo.Campaigns.SmsCampaign do
  @moduledoc """
  A draft or sent SMS blast for the volunteer phone database.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft sending sent)

  schema "sms_campaigns" do
    field :title, :string
    field :sender_id, :string
    field :message, :string
    field :callback_url, :string

    field :status, :string, default: "draft"
    field :recipient_count, :integer, default: 0
    field :sent_count, :integer, default: 0
    field :failed_count, :integer, default: 0
    field :sent_at, :utc_datetime

    has_many :deliveries, MaragaInfo.Campaigns.SmsDelivery, foreign_key: :campaign_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [
      :title,
      :sender_id,
      :message,
      :callback_url
    ])
    |> update_change(:title, &squish/1)
    |> update_change(:sender_id, &squish/1)
    |> update_change(:callback_url, &squish/1)
    |> update_change(:message, &trim_text/1)
    |> validate_required([:title, :sender_id, :message, :callback_url])
    |> validate_length(:title, max: 160)
    |> validate_length(:sender_id, max: 40)
    |> validate_length(:message, max: 1_000)
    |> validate_length(:callback_url, max: 500)
    |> validate_inclusion(:status, @statuses)
  end

  def statuses, do: @statuses

  defp squish(nil), do: nil

  defp squish(value) when is_binary(value) do
    case value |> String.trim() |> String.replace(~r/\s+/, " ") do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp trim_text(nil), do: nil

  defp trim_text(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end
end
