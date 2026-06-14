defmodule MaragaInfo.Content.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias MaragaInfo.Accounts.User
  alias MaragaInfo.Content.PostSection

  @newsletter_category "Newsletter"
  @canva_embed_regex ~r{^https://(www\.)?canva\.com/design/[^/]+/[^/]+/view}

  @doc "The category whose posts carry a Canva embed."
  def newsletter_category, do: @newsletter_category

  schema "posts" do
    field :title, :string
    field :category, :string
    field :body, :string
    field :slug, :string
    field :excerpt, :string
    field :seo_description, :string
    field :image_url, :string
    field :intro, :string
    field :canva_embed_url, :string
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
      :canva_embed_url,
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
    |> validate_canva_embed()
    |> put_slug()
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      message: "must use lowercase letters, numbers, and hyphens only"
    )
    |> maybe_put_published_at()
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:user_id)
  end

  # Newsletter posts must carry a valid Canva embed link; other categories
  # ignore the field entirely.
  defp validate_canva_embed(changeset) do
    if get_field(changeset, :category) == @newsletter_category do
      changeset
      |> validate_required([:canva_embed_url])
      |> validate_format(:canva_embed_url, @canva_embed_regex,
        message: "must be a Canva embed link (e.g. https://www.canva.com/design/.../view?embed)"
      )
    else
      changeset
    end
  end

  @doc """
  Returns true when the given string looks like a Canva design embed link.
  """
  def canva_embed_url?(nil), do: false

  def canva_embed_url?(url) when is_binary(url),
    do: Regex.match?(@canva_embed_regex, String.trim(url))

  @doc """
  Normalises a Canva design link into an embeddable iframe `src` by ensuring
  the `?embed` query parameter is present. Returns nil for non-Canva links.
  """
  def canva_embed_src(url) when is_binary(url) do
    url = String.trim(url)

    cond do
      not canva_embed_url?(url) -> nil
      String.contains?(url, "embed") -> url
      String.contains?(url, "?") -> url <> "&embed"
      true -> url <> "?embed"
    end
  end

  def canva_embed_src(_), do: nil

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
