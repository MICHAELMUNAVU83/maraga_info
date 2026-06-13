defmodule MaragaInfo.Content.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias MaragaInfo.Accounts.User
  alias MaragaInfo.Content.PostSection

  schema "posts" do
    field :title, :string
    field :category, :string
    field :body, :string
    field :slug, :string
    field :excerpt, :string
    field :seo_description, :string
    field :image_url, :string
    field :intro, :string
    field :status, Ecto.Enum, values: [:draft, :published], default: :draft
    field :published_at, :utc_datetime
    field :is_featured, :boolean, default: false
    belongs_to :author, User, foreign_key: :user_id

    embeds_many :sections, PostSection, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [
      :title,
      :slug,
      :category,
      :excerpt,
      :seo_description,
      :image_url,
      :intro,
      :body,
      :status,
      :published_at,
      :is_featured,
      :user_id
    ])
    |> cast_embed(:sections, with: &PostSection.changeset/2)
    |> validate_required([
      :title,
      :category,
      :excerpt,
      :seo_description,
      :image_url,
      :intro,
      :status
    ])
    |> validate_length(:title, max: 160)
    |> validate_length(:category, max: 80)
    |> validate_length(:excerpt, max: 320)
    |> validate_length(:seo_description, max: 320)
    |> validate_format(:image_url, ~r/^(\/|https?:\/\/)/,
      message: "must start with /, http://, or https://"
    )
    |> put_slug()
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      message: "must use lowercase letters, numbers, and hyphens only"
    )
    |> maybe_put_published_at()
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:user_id)
  end

  defp put_slug(changeset) do
    title = get_field(changeset, :title)
    slug = get_field(changeset, :slug)

    cond do
      is_binary(slug) and String.trim(slug) != "" ->
        put_change(changeset, :slug, slugify(slug))

      is_binary(title) and String.trim(title) != "" ->
        put_change(changeset, :slug, slugify(title))

      true ->
        changeset
    end
  end

  defp maybe_put_published_at(changeset) do
    if get_field(changeset, :status) == :published && is_nil(get_field(changeset, :published_at)) do
      put_change(changeset, :published_at, DateTime.utc_now() |> DateTime.truncate(:second))
    else
      changeset
    end
  end

  defp slugify(value) do
    value
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end
end
