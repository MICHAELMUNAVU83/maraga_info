defmodule MaragaInfo.Repo.Migrations.CreateMediaItems do
  use Ecto.Migration

  def change do
    create table(:media_items) do
      add :title, :string, null: false
      add :description, :text
      add :category, :string, null: false
      add :image_url, :string, null: false
      add :is_published, :boolean, default: true, null: false
      add :position, :integer, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:media_items, [:category])
    create index(:media_items, [:is_published])
    create index(:media_items, [:position])
  end
end
