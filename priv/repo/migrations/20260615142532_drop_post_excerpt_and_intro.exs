defmodule MaragaInfo.Repo.Migrations.DropPostExcerptAndIntro do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      remove :excerpt, :text
      remove :intro, :text
    end
  end
end
