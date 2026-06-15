defmodule MaragaInfo.Repo.Migrations.CreateEmailCampaigns do
  use Ecto.Migration

  def change do
    create table(:email_campaigns) do
      add :subject, :string, null: false
      add :preheader, :string
      add :body, :text, null: false
      add :sender_name, :string, null: false
      add :sender_title, :string
      add :reply_to, :string

      # draft | sending | sent
      add :status, :string, null: false, default: "draft"

      add :recipient_count, :integer, null: false, default: 0
      add :sent_count, :integer, null: false, default: 0
      add :failed_count, :integer, null: false, default: 0

      add :sent_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:email_campaigns, [:status])
    create index(:email_campaigns, [:inserted_at])

    create table(:email_deliveries) do
      add :campaign_id, references(:email_campaigns, on_delete: :delete_all), null: false
      add :email, :string, null: false
      add :name, :string

      # pending | sent | failed
      add :status, :string, null: false, default: "pending"
      add :error, :string
      add :sent_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:email_deliveries, [:campaign_id])
    create index(:email_deliveries, [:status])
    create unique_index(:email_deliveries, [:campaign_id, :email])
  end
end
