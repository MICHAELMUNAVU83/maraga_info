defmodule MaragaInfo.Repo.Migrations.AddDisplayOnLandingToMediaItems do
  use Ecto.Migration

  def change do
    alter table(:media_items) do
      add :display_on_landing, :boolean, default: false, null: false
    end

    create index(:media_items, [:display_on_landing])
  end
end
