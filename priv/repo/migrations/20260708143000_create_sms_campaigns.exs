defmodule MaragaInfo.Repo.Migrations.CreateSmsCampaigns do
  use Ecto.Migration

  def change do
    create table(:sms_campaigns) do
      add :title, :string, null: false
      add :sender_id, :string, null: false
      add :message, :text, null: false
      add :callback_url, :text, null: false
      add :status, :string, null: false, default: "draft"
      add :recipient_count, :integer, null: false, default: 0
      add :sent_count, :integer, null: false, default: 0
      add :failed_count, :integer, null: false, default: 0
      add :sent_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create table(:sms_deliveries) do
      add :campaign_id, references(:sms_campaigns, on_delete: :delete_all), null: false
      add :phone, :string, null: false
      add :name, :string
      add :status, :string, null: false, default: "pending"
      add :error, :text
      add :provider_response, :text
      add :sent_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:sms_campaigns, [:status])
    create index(:sms_deliveries, [:campaign_id])
    create index(:sms_deliveries, [:status])
    create unique_index(:sms_deliveries, [:campaign_id, :phone])
  end
end
