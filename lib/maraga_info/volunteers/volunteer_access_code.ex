defmodule MaragaInfo.Volunteers.VolunteerAccessCode do
  @moduledoc """
  One-time email code used to unlock the volunteer admin list.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "volunteer_access_codes" do
    field :email, :string
    field :code_hash, :string
    field :salt, :string
    field :expires_at, :utc_datetime
    field :used_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(access_code, attrs) do
    access_code
    |> cast(attrs, [:email, :code_hash, :salt, :expires_at, :used_at])
    |> validate_required([:email, :code_hash, :salt, :expires_at])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end
end
