defmodule MaragaInfo.Repo.Migrations.AddImageUrlToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :image_url, :string
    end
  end
end
