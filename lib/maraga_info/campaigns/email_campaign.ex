defmodule MaragaInfo.Campaigns.EmailCampaign do
  @moduledoc """
  A designed email blast that can be sent to the volunteer database.

  The `body` is a complete HTML email document authored by the admin and sent
  as-is. The placeholders `{{name}}` / `{{first_name}}` are replaced per
  recipient when the email is rendered.

  When `ab_test` is true the campaign carries a second variant in the `*_b`
  fields. At send time the recipient pool is divided evenly between variant A
  (`subject`/`sender_name`/`body`) and variant B (`subject_b`/`sender_name_b`/
  `body_b`).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft sending sent)
  @variants ~w(A B)

  schema "email_campaigns" do
    # Variant A (and the only content when ab_test is false)
    field :subject, :string
    field :body, :string
    field :sender_name, :string

    # Variant B (only used when ab_test is true)
    field :ab_test, :boolean, default: false
    field :subject_b, :string
    field :body_b, :string
    field :sender_name_b, :string

    # Section-based builder (takes precedence over body when non-empty)
    field :sections, {:array, :map}, default: []

    # Shared metadata
    field :preheader, :string
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
    |> cast(attrs, [
      :subject,
      :body,
      :sender_name,
      :ab_test,
      :subject_b,
      :body_b,
      :sender_name_b,
      :preheader,
      :sender_title,
      :reply_to,
      :sections
    ])
    |> update_change(:subject, &squish/1)
    |> update_change(:subject_b, &squish/1)
    |> update_change(:preheader, &squish/1)
    |> update_change(:sender_name, &squish/1)
    |> update_change(:sender_name_b, &squish/1)
    |> update_change(:sender_title, &squish/1)
    |> update_change(:reply_to, &normalize_email/1)
    |> validate_required([:subject, :body, :sender_name])
    |> validate_variant_b()
    |> validate_length(:subject, max: 200)
    |> validate_length(:subject_b, max: 200)
    |> validate_length(:preheader, max: 200)
    |> validate_length(:sender_name, max: 120)
    |> validate_length(:sender_name_b, max: 120)
    |> validate_length(:sender_title, max: 160)
    |> validate_format(:reply_to, ~r/^[^\s]+@[^\s]+$/,
      message: "must be a valid email",
      allow_blank: true
    )
    |> validate_inclusion(:status, @statuses)
  end

  # Variant B content is only required once A/B testing is switched on.
  defp validate_variant_b(changeset) do
    if get_field(changeset, :ab_test) do
      validate_required(changeset, [:subject_b, :body_b, :sender_name_b],
        message: "is required for the B variant"
      )
    else
      changeset
    end
  end

  def statuses, do: @statuses
  def variants, do: @variants

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
