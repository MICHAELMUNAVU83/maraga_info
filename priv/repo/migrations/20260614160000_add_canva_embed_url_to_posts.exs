defmodule MaragaInfo.Repo.Migrations.AddCanvaEmbedUrlToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :canva_embed_url, :string
    end
  end
end
