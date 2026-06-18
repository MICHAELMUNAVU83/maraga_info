defmodule MaragaInfoWeb.Admin.PostLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfo.Content.Post

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:scope, scope_from_path("/admin/posts"))
     |> assign(:page_title, "Posts")
     |> assign(:page_subtitle, "Manage the published and draft stories that appear on the site.")
     |> assign(:stats, post_stats([]))
     |> assign(:search_query, "")
     |> stream(:posts, [])}
  end

  @impl true
  def handle_params(params, url, socket) do
    path = URI.parse(url).path
    scope = scope_from_path(path)
    search_query = Map.get(params, "q", "")

    {:noreply,
     socket
     |> assign(:current_path, path)
     |> assign(:scope, scope)
     |> assign(:page_title, scope.title)
     |> assign(:page_subtitle, scope.subtitle)
     |> assign(:search_query, search_query)
     |> load_posts()}
  end

  @impl true
  def handle_event("search", %{"search" => %{"q" => query}}, socket) do
    {:noreply, push_patch(socket, to: search_path(socket.assigns.scope, query))}
  end

  def handle_event("clear_search", _params, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.scope.base_path)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Content.get_post!(id)
    {:ok, _} = Content.delete_post(post)

    {:noreply,
     socket
     |> put_flash(:info, "#{socket.assigns.scope.singular_title} deleted")
     |> load_posts()}
  end

  defp load_posts(socket) do
    posts =
      Content.list_posts(
        scope: socket.assigns.scope.scope,
        search: socket.assigns.search_query
      )

    socket
    |> assign(:stats, post_stats(posts))
    |> stream(:posts, posts, reset: true)
  end

  defp scope_from_path(path) do
    cond do
      String.starts_with?(path, "/admin/newsletters") ->
        %{
          scope: :newsletters,
          title: "Newsletters",
          subtitle: "Manage newsletter issues, volume numbers, and published editions.",
          singular_title: "Newsletter",
          new_label: "New newsletter",
          base_path: "/admin/newsletters",
          panel_title: "All newsletters",
          panel_subtitle: "Search and manage every published or draft newsletter edition.",
          empty_title: "No newsletters yet",
          empty_description: "Create the first newsletter issue to start the archive."
        }

      String.starts_with?(path, "/admin/press-releases") ->
        %{
          scope: :press_releases,
          title: "Press Releases",
          subtitle: "Publish official statements, releases, and campaign announcements.",
          singular_title: "Press release",
          new_label: "New press release",
          base_path: "/admin/press-releases",
          panel_title: "All press releases",
          panel_subtitle: "Search and manage official press communications.",
          empty_title: "No press releases yet",
          empty_description: "Create the first press release to start the press archive."
        }

      String.starts_with?(path, "/admin/media-invitations") ->
        %{
          scope: :media_invitations,
          title: "Media Invitations",
          subtitle: "Manage invitation notices and media advisories for the press corps.",
          singular_title: "Media invitation",
          new_label: "New media invitation",
          base_path: "/admin/media-invitations",
          panel_title: "All media invitations",
          panel_subtitle: "Search and manage media advisories and event invites.",
          empty_title: "No media invitations yet",
          empty_description: "Create the first media invitation to brief reporters and editors."
        }

      String.starts_with?(path, "/admin/blogs") ->
        %{
          scope: :blogs,
          title: "Blogs",
          subtitle: "Write and publish long-form blog articles for the /blog section.",
          singular_title: "Blog post",
          new_label: "New blog post",
          base_path: "/admin/blogs",
          panel_title: "All blog posts",
          panel_subtitle: "Search, review, and manage every blog article.",
          empty_title: "No blog posts yet",
          empty_description: "Create the first blog article to start the blog section."
        }

      true ->
        %{
          scope: :posts,
          title: "Posts",
          subtitle: "Create, review, and publish the stories that appear on the public website.",
          singular_title: "Post",
          new_label: "New post",
          base_path: "/admin/posts",
          panel_title: "All posts",
          panel_subtitle: "Search, review, and manage every article on the site.",
          empty_title: "No posts yet",
          empty_description:
            "Create the first story to start building out the public news section."
        }
    end
  end

  defp search_path(scope, query) do
    trimmed = String.trim(query || "")

    if trimmed == "" do
      scope.base_path
    else
      scope.base_path <> "?q=" <> URI.encode_www_form(trimmed)
    end
  end

  defp show_path(scope, post), do: scope.base_path <> "/#{post.id}"
  defp edit_path(scope, post), do: scope.base_path <> "/#{post.id}/edit"
  defp new_path(scope), do: scope.base_path <> "/new"

  defp post_stats(posts) do
    Enum.reduce(posts, %{total: length(posts), published: 0, drafts: 0, featured: 0}, fn post,
                                                                                         acc ->
      acc
      |> increment_if(:published, post.status == :published)
      |> increment_if(:drafts, post.status == :draft)
      |> increment_if(:featured, post.is_featured)
    end)
  end

  defp increment_if(map, key, true), do: Map.update!(map, key, &(&1 + 1))
  defp increment_if(map, _key, false), do: map

  defp format_datetime(nil), do: "Not scheduled"
  defp format_datetime(datetime), do: Calendar.strftime(datetime, "%d %b %Y")

  defp volume_label(%Post{newsletter_volume: volume}) when is_binary(volume) and volume != "",
    do: volume

  defp volume_label(_post), do: "—"
end
