defmodule MaragaInfo.Content.MediaItem do
  @moduledoc """
  A single image in the public media gallery. Each item belongs to a category
  so the gallery page can offer filtered views (All, Public, Political, ...).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @categories ~w(Public Political Senate Events Rallies Press)

  schema "media_items" do
    field :title, :string
    field :description, :string
    field :category, :string
    field :image_url, :string
    field :is_published, :boolean, default: true
    field :display_on_landing, :boolean, default: false
    field :position, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  @doc "The set of suggested categories surfaced in the admin form."
  def categories, do: @categories

  @doc false
  def changeset(media_item, attrs) do
    media_item
    |> cast(attrs, [
      :title,
      :description,
      :category,
      :image_url,
      :is_published,
      :display_on_landing,
      :position
    ])
    |> validate_required([:title, :category, :image_url])
    |> validate_length(:title, max: 160)
    |> validate_length(:category, max: 80)
    |> validate_format(:image_url, ~r/^(\/|https?:\/\/)/,
      message: "must start with /, http://, or https://"
    )
  end
end
