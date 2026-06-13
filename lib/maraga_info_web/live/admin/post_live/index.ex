defmodule MaragaInfoWeb.Admin.PostLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content

  @impl true
  def mount(_params, _session, socket) do
    posts = Content.list_posts()

    {:ok,
     socket
     |> assign(:page_title, "Blogs")
     |> assign(
       :page_subtitle,
       "Create, review, and publish the stories that appear on the public website."
     )
     |> assign(:stats, post_stats(posts))
     |> stream(:posts, posts)}
  end

  @impl true
  def handle_params(_params, url, socket) do
    {:noreply, assign(socket, :current_path, URI.parse(url).path)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Content.get_post!(id)
    {:ok, _} = Content.delete_post(post)
    posts = Content.list_posts()

    {:noreply,
     socket
     |> assign(:stats, post_stats(posts))
     |> stream_delete(:posts, post)}
  end

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
end
