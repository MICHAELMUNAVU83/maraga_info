defmodule MaragaInfo.Content do
  @moduledoc """
  The Content context.
  """

  import Ecto.Query, warn: false
  alias MaragaInfo.Repo

  alias MaragaInfo.Accounts.User
  alias MaragaInfo.Content.Event
  alias MaragaInfo.Content.MediaItem
  alias MaragaInfo.Content.Post

  @doc """
  Returns the canonical list of post categories used in the admin form.
  """
  def post_categories(scope \\ :all)

  def post_categories(:posts), do: Post.general_categories()
  def post_categories(:blogs), do: [Post.blog_category()]
  def post_categories(:all), do: Post.all_categories()
  def post_categories(_scope), do: Post.all_categories()

  @doc """
  Returns published newsletter posts, newest first.
  """
  def list_published_newsletters(opts \\ []) do
    opts
    |> Keyword.put(:category, Post.newsletter_category())
    |> list_published_posts()
  end

  @doc """
  Returns published blog posts, newest first.
  """
  def list_published_blogs(opts \\ []) do
    opts
    |> Keyword.put(:category, Post.blog_category())
    |> list_published_posts()
  end

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts(opts \\ []) do
    Post
    |> maybe_filter_status(Keyword.get(opts, :status))
    |> maybe_filter_post_scope(Keyword.get(opts, :scope))
    |> maybe_filter_post_category(Keyword.get(opts, :category))
    |> maybe_filter_post_search(Keyword.get(opts, :search))
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
  Returns the distinct categories used by published posts, sorted.
  """
  def list_published_post_categories(opts \\ []) do
    Post
    |> where([post], post.status == :published)
    |> maybe_filter_post_scope(Keyword.get(opts, :scope))
    |> select([post], post.category)
    |> distinct(true)
    |> Repo.all()
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.sort()
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

  defp maybe_filter_post_category(query, nil), do: query
  defp maybe_filter_post_category(query, "all"), do: query
  defp maybe_filter_post_category(query, ""), do: query

  defp maybe_filter_post_category(query, category) do
    where(query, [post], post.category == ^category)
  end

  defp maybe_filter_post_scope(query, nil), do: query
  defp maybe_filter_post_scope(query, :all), do: query

  defp maybe_filter_post_scope(query, :posts) do
    where(query, [post], post.category not in ^Post.special_categories())
  end

  defp maybe_filter_post_scope(query, :newsletters) do
    where(query, [post], post.category == ^Post.newsletter_category())
  end

  defp maybe_filter_post_scope(query, :press_releases) do
    where(query, [post], post.category == ^Post.press_release_category())
  end

  defp maybe_filter_post_scope(query, :media_invitations) do
    where(query, [post], post.category == ^Post.media_invitation_category())
  end

  defp maybe_filter_post_scope(query, :blogs) do
    where(query, [post], post.category == ^Post.blog_category())
  end

  defp maybe_filter_post_search(query, nil), do: query

  defp maybe_filter_post_search(query, search) when is_binary(search) do
    trimmed = String.trim(search)

    if trimmed == "" do
      query
    else
      pattern = "%#{trimmed}%"

      where(
        query,
        [post],
        ilike(post.title, ^pattern) or ilike(post.slug, ^pattern) or
          ilike(post.category, ^pattern)
      )
    end
  end

  defp order_posts(query) do
    order_by(query, [post],
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
    |> maybe_filter_media_type(Keyword.get(opts, :media_type))
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
  Returns published media items flagged to show on the landing page gallery.
  """
  def list_landing_media_items do
    MediaItem
    |> where(
      [item],
      item.is_published == true and item.display_on_landing == true and item.media_type == "photo"
    )
    |> order_by([item], asc: item.position, desc: item.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns the distinct categories used by published media items, sorted.
  """
  def list_published_media_categories(opts \\ []) do
    MediaItem
    |> where([item], item.is_published == true)
    |> maybe_filter_media_type(Keyword.get(opts, :media_type))
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

  defp maybe_filter_media_type(query, nil), do: query
  defp maybe_filter_media_type(query, :all), do: query
  defp maybe_filter_media_type(query, "all"), do: query

  defp maybe_filter_media_type(query, media_type) do
    where(query, [item], item.media_type == ^to_string(media_type))
  end

  ## Events

  @doc """
  Returns events ordered by start time (soonest first).

  Pass `status: :published` to limit to events shown on the public calendar, or
  `from: datetime` to only include events that start on or after a given time.
  """
  def list_events(opts \\ []) do
    Event
    |> maybe_filter_event_published(Keyword.get(opts, :status))
    |> maybe_filter_event_from(Keyword.get(opts, :from))
    |> order_by([event], asc: event.starts_at)
    |> maybe_limit(Keyword.get(opts, :limit))
    |> Repo.all()
  end

  def list_published_events(opts \\ []) do
    opts
    |> Keyword.put(:status, :published)
    |> list_events()
  end

  @doc """
  Returns published events that start on or after the current time, soonest first.
  """
  def list_upcoming_events(opts \\ []) do
    opts
    |> Keyword.put(:from, DateTime.utc_now())
    |> list_published_events()
  end

  def get_event!(id), do: Repo.get!(Event, id)

  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  defp maybe_filter_event_published(query, :published) do
    where(query, [event], event.is_published == true)
  end

  defp maybe_filter_event_published(query, _), do: query

  defp maybe_filter_event_from(query, nil), do: query

  defp maybe_filter_event_from(query, %DateTime{} = from) do
    where(query, [event], event.starts_at >= ^from)
  end
end
