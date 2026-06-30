defmodule MaragaInfo.Repo.Migrations.AddSectionsToEmailCampaigns do
  use Ecto.Migration

  def change do
    alter table(:email_campaigns) do
      add :sections, {:array, :map}, default: []
    end
  end
end
