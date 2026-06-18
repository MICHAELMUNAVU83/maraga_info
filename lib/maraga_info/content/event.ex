defmodule MaragaInfo.Content.Event do
  @moduledoc """
  A single campaign event shown on the in-built Events Calendar. Each event has
  a start (and optional end) time, a location, and a publish flag controlling
  whether it appears on the public calendar.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :title, :string
    field :description, :string
    field :location, :string
    field :image_url, :string
    field :starts_at, :utc_datetime
    field :ends_at, :utc_datetime
    field :all_day, :boolean, default: false
    field :is_published, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :title,
      :description,
      :location,
      :image_url,
      :starts_at,
      :ends_at,
      :all_day,
      :is_published
    ])
    |> validate_required([:title, :starts_at])
    |> validate_length(:title, max: 160)
    |> validate_length(:location, max: 160)
    |> validate_end_after_start()
  end

  defp validate_end_after_start(changeset) do
    starts_at = get_field(changeset, :starts_at)
    ends_at = get_field(changeset, :ends_at)

    if starts_at && ends_at && DateTime.compare(ends_at, starts_at) == :lt do
      add_error(changeset, :ends_at, "must be after the start time")
    else
      changeset
    end
  end
end
