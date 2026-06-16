defmodule MaragaInfo.Repo.Migrations.AddNewsletterVolumeAndVideoMedia do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :newsletter_volume, :string
    end

    alter table(:media_items) do
      add :media_type, :string, null: false, default: "photo"
      add :video_url, :string
      modify :image_url, :string, null: true
    end

    create index(:media_items, [:media_type])
  end
end
