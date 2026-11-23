defmodule MaragaInfo.Repo.Migrations.CreateVoterDriveRegistrations do
  use Ecto.Migration

  def change do
    create table(:voter_drive_registrations) do
      add :source_id, :string
      add :first_name, :string
      add :last_name, :string
      add :phone, :string
      add :email, :string, null: false
      add :county, :string
      add :constituency, :string
      add :ward, :string
      add :polling_station, :string
      add :interests, {:array, :string}, null: false, default: []
      add :additional_info, :text
      add :registered_on, :date
      add :source_updated_on, :date

      timestamps(type: :utc_datetime)
    end

    create unique_index(:voter_drive_registrations, [:source_id], where: "source_id IS NOT NULL")

    create index(:voter_drive_registrations, [:email])
    create index(:voter_drive_registrations, [:phone])
    create index(:voter_drive_registrations, [:county])
  end
end
