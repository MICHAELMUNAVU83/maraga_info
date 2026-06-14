defmodule MaragaInfo.Repo.Migrations.CreateVolunteers do
  use Ecto.Migration

  def change do
    create table(:volunteers) do
      add :source_id, :string
      add :first_name, :string
      add :last_name, :string
      add :full_name, :string
      add :email, :string, null: false
      add :phone, :string
      add :county, :string
      add :constituency, :string
      add :ward, :string
      add :polling_station, :string
      add :additional_info, :text
      add :joined_on, :date
      add :source_updated_on, :date

      timestamps(type: :utc_datetime)
    end

    create unique_index(:volunteers, [:email])
    create index(:volunteers, [:county])
    create index(:volunteers, [:source_updated_on])
  end
end
