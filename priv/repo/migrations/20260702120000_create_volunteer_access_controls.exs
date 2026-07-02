defmodule MaragaInfo.Repo.Migrations.CreateVolunteerAccessControls do
  use Ecto.Migration

  def change do
    create table(:volunteer_access_codes) do
      add :email, :string, null: false
      add :code_hash, :string, null: false
      add :salt, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :used_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:volunteer_access_codes, [:email])
    create index(:volunteer_access_codes, [:expires_at])

    create table(:volunteer_views) do
      add :email, :string, null: false
      add :viewed_at, :utc_datetime, null: false
      add :access_method, :string, null: false, default: "email_code"

      timestamps(type: :utc_datetime)
    end

    create index(:volunteer_views, [:viewed_at])
    create index(:volunteer_views, [:email])
  end
end
