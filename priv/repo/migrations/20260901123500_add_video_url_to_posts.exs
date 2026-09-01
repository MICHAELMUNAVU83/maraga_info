defmodule MaragaInfo.Repo.Migrations.AddVideoUrlToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :video_url, :string
    end
  end
end
