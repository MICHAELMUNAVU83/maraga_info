defmodule MaragaInfo.Content.MediaItem do
  @moduledoc """
  A single image in the public media gallery. Each item belongs to a category
  so the gallery page can offer filtered views (All, Public, Political, ...).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @categories ~w(Public Political Senate Events Rallies Press)
  @media_types ~w(photo video)

  schema "media_items" do
    field :title, :string
    field :description, :string
    field :category, :string
    field :image_url, :string
    field :video_url, :string
    field :media_type, :string, default: "photo"
    field :is_published, :boolean, default: true
    field :display_on_landing, :boolean, default: false
    field :position, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  @doc "The set of suggested categories surfaced in the admin form."
  def categories, do: @categories

  @doc "The supported asset types surfaced in the admin form."
  def media_types, do: @media_types

  @doc false
  def changeset(media_item, attrs) do
    media_item
    |> cast(attrs, [
      :title,
      :description,
      :category,
      :image_url,
      :video_url,
      :media_type,
      :is_published,
      :display_on_landing,
      :position
    ])
    |> validate_required([:title, :category, :media_type])
    |> validate_length(:title, max: 160)
    |> validate_length(:category, max: 80)
    |> validate_inclusion(:media_type, @media_types)
    |> validate_format(:image_url, ~r/^(\/|https?:\/\/)/,
      message: "must start with /, http://, or https://"
    )
    |> validate_format(:video_url, ~r/^(\/|https?:\/\/)/,
      message: "must start with /, http://, or https://"
    )
    |> validate_asset_presence()
  end

  defp validate_asset_presence(changeset) do
    case get_field(changeset, :media_type) do
      "video" ->
        validate_required(changeset, [:video_url])

      _ ->
        validate_required(changeset, [:image_url])
    end
  end
end
