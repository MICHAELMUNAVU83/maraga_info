defmodule MaragaInfo.Repo.Migrations.AddHtmlAndAbTestingToCampaigns do
  use Ecto.Migration

  @moduledoc """
  Moves campaigns to full-HTML email bodies and adds optional A/B testing.

  When `ab_test` is true a campaign carries a second variant (the `*_b`
  columns). At send time the recipient pool is divided evenly between the two
  variants, and each delivery records which `variant` it received so per-variant
  progress can be reported.
  """

  def change do
    alter table(:email_campaigns) do
      add :ab_test, :boolean, null: false, default: false

      # Variant B content (only used when ab_test is true).
      add :subject_b, :string
      add :sender_name_b, :string
      add :body_b, :text
    end

    alter table(:email_deliveries) do
      # Which variant this recipient was sent: "A" or "B".
      add :variant, :string, null: false, default: "A"
    end

    create index(:email_deliveries, [:variant])
  end
end
