defmodule MaragaInfo.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :title, :string, null: false
      add :description, :text
      add :location, :string
      add :starts_at, :utc_datetime, null: false
      add :ends_at, :utc_datetime
      add :all_day, :boolean, default: false, null: false
      add :is_published, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:events, [:starts_at])
    create index(:events, [:is_published])
  end
end
