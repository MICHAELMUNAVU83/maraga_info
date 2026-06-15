defmodule MaragaInfo.Campaigns.EmailCampaign do
  @moduledoc """
  A designed email blast that can be sent to the volunteer database.

  The `body` is plain text written by the admin. Blank lines separate
  paragraphs and the placeholders `{{name}}` / `{{first_name}}` are replaced
  per recipient when the email is rendered.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft sending sent)

  schema "email_campaigns" do
    field :subject, :string
    field :preheader, :string
    field :body, :string
    field :sender_name, :string
    field :sender_title, :string
    field :reply_to, :string
    field :status, :string, default: "draft"
    field :recipient_count, :integer, default: 0
    field :sent_count, :integer, default: 0
    field :failed_count, :integer, default: 0
    field :sent_at, :utc_datetime

    has_many :deliveries, MaragaInfo.Campaigns.EmailDelivery, foreign_key: :campaign_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [:subject, :preheader, :body, :sender_name, :sender_title, :reply_to])
    |> update_change(:subject, &squish/1)
    |> update_change(:preheader, &squish/1)
    |> update_change(:sender_name, &squish/1)
    |> update_change(:sender_title, &squish/1)
    |> update_change(:reply_to, &normalize_email/1)
    |> validate_required([:subject, :body, :sender_name])
    |> validate_length(:subject, max: 200)
    |> validate_length(:preheader, max: 200)
    |> validate_length(:sender_name, max: 120)
    |> validate_length(:sender_title, max: 160)
    |> validate_format(:reply_to, ~r/^[^\s]+@[^\s]+$/,
      message: "must be a valid email",
      allow_blank: true
    )
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

  defp normalize_email(nil), do: nil

  defp normalize_email(value) when is_binary(value) do
    case value |> String.trim() |> String.downcase() do
      "" -> nil
      email -> email
    end
  end
end
