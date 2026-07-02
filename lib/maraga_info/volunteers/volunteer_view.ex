defmodule MaragaInfo.Volunteers.VolunteerView do
  @moduledoc """
  Audit record for each successful volunteer list unlock.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "volunteer_views" do
    field :email, :string
    field :viewed_at, :utc_datetime
    field :access_method, :string, default: "email_code"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(volunteer_view, attrs) do
    volunteer_view
    |> cast(attrs, [:email, :viewed_at, :access_method])
    |> validate_required([:email, :viewed_at, :access_method])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> validate_length(:access_method, max: 80)
  end
end
