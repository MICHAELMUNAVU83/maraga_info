defmodule MaragaInfo.Volunteers.Volunteer do
  @moduledoc """
  A volunteer record imported from campaign collection sheets or created
  manually in the admin.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "volunteers" do
    field :source_id, :string
    field :first_name, :string
    field :last_name, :string
    field :full_name, :string
    field :email, :string
    field :phone, :string
    field :county, :string
    field :constituency, :string
    field :ward, :string
    field :polling_station, :string
    field :additional_info, :string
    field :joined_on, :date
    field :source_updated_on, :date

    timestamps(type: :utc_datetime)
  end

  @fields [
    :source_id,
    :first_name,
    :last_name,
    :full_name,
    :email,
    :phone,
    :county,
    :constituency,
    :ward,
    :polling_station,
    :additional_info,
    :joined_on,
    :source_updated_on
  ]

  @doc false
  def changeset(volunteer, attrs) do
    volunteer
    |> cast(attrs, @fields)
    |> normalize_text_field(:source_id)
    |> normalize_text_field(:first_name)
    |> normalize_text_field(:last_name)
    |> normalize_text_field(:full_name)
    |> normalize_text_field(:phone)
    |> normalize_text_field(:county)
    |> normalize_text_field(:constituency)
    |> normalize_text_field(:ward)
    |> normalize_text_field(:polling_station)
    |> normalize_text_field(:additional_info, squish: false)
    |> update_change(:email, &normalize_email/1)
    |> put_full_name()
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> validate_length(:first_name, max: 120)
    |> validate_length(:last_name, max: 120)
    |> validate_length(:full_name, max: 220)
    |> validate_length(:phone, max: 80)
    |> validate_length(:county, max: 120)
    |> validate_length(:constituency, max: 120)
    |> validate_length(:ward, max: 120)
    |> validate_length(:polling_station, max: 200)
    |> unique_constraint(:email)
  end

  def normalize_email(nil), do: nil

  def normalize_email(email) when is_binary(email) do
    email
    |> String.trim()
    |> String.downcase()
    |> blank_to_nil()
  end

  defp normalize_text_field(changeset, field, opts \\ []) do
    squish? = Keyword.get(opts, :squish, true)

    update_change(changeset, field, fn value ->
      value
      |> normalize_text(squish?)
      |> blank_to_nil()
    end)
  end

  defp normalize_text(nil, _squish?), do: nil

  defp normalize_text(value, squish?) when is_binary(value) do
    value =
      if squish? do
        value
        |> String.trim()
        |> String.replace(~r/\s+/, " ")
      else
        String.trim(value)
      end

    blank_to_nil(value)
  end

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value

  defp put_full_name(changeset) do
    case get_field(changeset, :full_name) do
      nil ->
        full_name =
          [get_field(changeset, :first_name), get_field(changeset, :last_name)]
          |> Enum.reject(&is_nil/1)
          |> Enum.join(" ")
          |> String.trim()

        if full_name == "" do
          changeset
        else
          put_change(changeset, :full_name, full_name)
        end

      _value ->
        changeset
    end
  end
end
