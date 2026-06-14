defmodule MaragaInfo.Content do
  @moduledoc """
  The Content context.
  """

  import Ecto.Query, warn: false
  alias MaragaInfo.Repo

  alias MaragaInfo.Accounts.User
  alias MaragaInfo.Content.MediaItem
  alias MaragaInfo.Content.Post

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts(opts \\ []) do
    Post
    |> maybe_filter_status(Keyword.get(opts, :status))
    |> order_posts()
    |> maybe_limit(Keyword.get(opts, :limit))
    |> Repo.all()
    |> Repo.preload(:author)
  end

  def list_published_posts(opts \\ []) do
    opts
    |> Keyword.put(:status, :published)
    |> list_posts()
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(id), do: Post |> Repo.get!(id) |> Repo.preload(:author)

  def get_post_by_slug(slug) when is_binary(slug) do
    Post
    |> where([post], post.slug == ^slug)
    |> Repo.one()
    |> preload_author()
  end

  def get_published_post_by_slug(slug) when is_binary(slug) do
    Post
    |> where([post], post.slug == ^slug and post.status == :published)
    |> Repo.one()
    |> preload_author()
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  def create_post(%User{} = user, attrs) do
    attrs = Map.new(attrs)
    user_key = if Enum.all?(Map.keys(attrs), &is_binary/1), do: "user_id", else: :user_id

    attrs
    |> Map.put(user_key, user.id)
    |> create_post()
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def adjacent_published_posts(%Post{} = post) do
    posts = list_published_posts()
    index = Enum.find_index(posts, &(&1.id == post.id))

    if is_nil(index) do
      {nil, nil}
    else
      {Enum.at(posts, index - 1), Enum.at(posts, index + 1)}
    end
  end

  defp maybe_filter_status(query, nil), do: query

  defp maybe_filter_status(query, status) do
    where(query, [post], post.status == ^status)
  end

  defp order_posts(query) do
    order_by(query, [post],
      desc: post.is_featured,
      desc: post.published_at,
      desc: post.inserted_at
    )
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, ^limit)

  defp preload_author(nil), do: nil
  defp preload_author(post), do: Repo.preload(post, :author)

  ## Media items

  @doc """
  Returns media items ordered for display.

  Pass `status: :published` to limit to items shown on the public gallery, or
  `category: "Events"` to scope to a single category.
  """
  def list_media_items(opts \\ []) do
    MediaItem
    |> maybe_filter_published(Keyword.get(opts, :status))
    |> maybe_filter_category(Keyword.get(opts, :category))
    |> order_by([item], asc: item.position, desc: item.inserted_at)
    |> Repo.all()
  end

  def list_published_media_items(opts \\ []) do
    opts
    |> Keyword.put(:status, :published)
    |> list_media_items()
  end

  @doc """
  Returns the distinct categories used by published media items, sorted.
  """
  def list_published_media_categories do
    MediaItem
    |> where([item], item.is_published == true)
    |> select([item], item.category)
    |> distinct(true)
    |> Repo.all()
    |> Enum.sort()
  end

  def get_media_item!(id), do: Repo.get!(MediaItem, id)

  def create_media_item(attrs \\ %{}) do
    %MediaItem{}
    |> MediaItem.changeset(attrs)
    |> Repo.insert()
  end

  def update_media_item(%MediaItem{} = media_item, attrs) do
    media_item
    |> MediaItem.changeset(attrs)
    |> Repo.update()
  end

  def delete_media_item(%MediaItem{} = media_item) do
    Repo.delete(media_item)
  end

  def change_media_item(%MediaItem{} = media_item, attrs \\ %{}) do
    MediaItem.changeset(media_item, attrs)
  end

  defp maybe_filter_published(query, :published) do
    where(query, [item], item.is_published == true)
  end

  defp maybe_filter_published(query, _), do: query

  defp maybe_filter_category(query, nil), do: query
  defp maybe_filter_category(query, "all"), do: query
  defp maybe_filter_category(query, ""), do: query

  defp maybe_filter_category(query, category) do
    where(query, [item], item.category == ^category)
  end
end
