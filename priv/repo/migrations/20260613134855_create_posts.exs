defmodule MaragaInfo.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :slug, :string
      add :category, :string
      add :excerpt, :text
      add :seo_description, :text
      add :image_url, :string
      add :intro, :text
      add :body, :text
      add :status, :string, null: false, default: "draft"
      add :published_at, :utc_datetime
      add :user_id, references(:users, on_delete: :nilify_all)
      add :is_featured, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:posts, [:slug])
    create index(:posts, [:status])
    create index(:posts, [:published_at])
    create index(:posts, [:user_id])
  end
end
