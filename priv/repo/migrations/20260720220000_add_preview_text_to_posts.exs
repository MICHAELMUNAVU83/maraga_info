defmodule MaragaInfo.Repo.Migrations.AddPreviewTextToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :preview_text, :text
    end
  end
end
