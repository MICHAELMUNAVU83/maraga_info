defmodule MaragaInfoWeb.Admin.PostLive.Show do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfoWeb.RichText

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, url, socket) do
    path = URI.parse(url).path
    scope = scope_from_path(path)

    {:noreply,
     socket
     |> assign(:current_path, path)
     |> assign(:scope, scope)
     |> assign(:page_subtitle, "Preview the #{scope.singular} and its metadata.")
     |> assign(:page_title, "Post details")
     |> assign(:post, Content.get_post!(id))}
  end

  defp scope_from_path(path) do
    cond do
      String.starts_with?(path, "/admin/newsletters") ->
        %{base_path: "/admin/newsletters", singular: "newsletter"}

      String.starts_with?(path, "/admin/press-releases") ->
        %{base_path: "/admin/press-releases", singular: "press release"}

      String.starts_with?(path, "/admin/media-invitations") ->
        %{base_path: "/admin/media-invitations", singular: "media invitation"}

      String.starts_with?(path, "/admin/blogs") ->
        %{base_path: "/admin/blogs", singular: "blog post"}

      true ->
        %{base_path: "/admin/posts", singular: "story"}
    end
  end

  defp back_path(scope), do: scope.base_path
  defp edit_path(scope, post), do: scope.base_path <> "/#{post.id}/edit"

  defp format_datetime(nil), do: "Not scheduled"
  defp format_datetime(datetime), do: Calendar.strftime(datetime, "%d %b %Y")

  defp render_body(text), do: RichText.render(text)

  defp author_email(%{author: %{email: email}}), do: email
  defp author_email(_post), do: "No author"
end
