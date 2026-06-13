defmodule MaragaInfo.Repo.Migrations.AddSectionsToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :sections, {:array, :map}, default: [], null: false
      modify :body, :text, null: true
    end
  end
end
