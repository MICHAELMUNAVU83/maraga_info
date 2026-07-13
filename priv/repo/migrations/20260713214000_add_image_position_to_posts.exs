defmodule MaragaInfo.Repo.Migrations.AddImagePositionToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :image_position_x, :integer, null: false, default: 50
      add :image_position_y, :integer, null: false, default: 50
    end

    create constraint(:posts, :image_position_x_percentage,
             check: "image_position_x >= 0 AND image_position_x <= 100"
           )

    create constraint(:posts, :image_position_y_percentage,
             check: "image_position_y >= 0 AND image_position_y <= 100"
           )
  end
end
