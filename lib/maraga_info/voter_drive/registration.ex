defmodule MaragaInfo.VoterDrive.Registration do
  use Ecto.Schema
  import Ecto.Changeset

  schema "voter_drive_registrations" do
    field :source_id, :string
    field :first_name, :string
    field :last_name, :string
    field :phone, :string
    field :email, :string
    field :county, :string
    field :constituency, :string
    field :ward, :string
    field :polling_station, :string
    field :interests, {:array, :string}, default: []
    field :additional_info, :string
    field :registered_on, :date
    field :source_updated_on, :date

    timestamps(type: :utc_datetime)
  end

  @fields ~w(source_id first_name last_name phone email county constituency ward polling_station interests additional_info registered_on source_updated_on)a
  @public_required ~w(first_name last_name phone email county constituency ward interests)a

  def changeset(registration, attrs) do
    registration
    |> cast(attrs, @fields)
    |> normalize_email()
    |> normalize_interests()
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email address")
    |> unique_constraint(:source_id)
  end

  def public_changeset(registration, attrs) do
    registration
    |> changeset(attrs)
    |> validate_required(@public_required)
    |> validate_length(:interests, min: 1, message: "choose at least one interest")
    |> validate_length(:additional_info, max: 5_000)
  end

  defp normalize_email(changeset) do
    update_change(changeset, :email, fn email -> email |> String.trim() |> String.downcase() end)
  end

  defp normalize_interests(changeset) do
    update_change(changeset, :interests, fn interests ->
      interests
      |> List.wrap()
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()
    end)
  end
end
