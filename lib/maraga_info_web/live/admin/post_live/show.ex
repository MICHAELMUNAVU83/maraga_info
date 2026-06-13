defmodule MaragaInfoWeb.Admin.PostLive.Show do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:current_path, "/admin/blogs")
     |> assign(:page_subtitle, "Preview the story and its metadata.")
     |> assign(:page_title, "Post details")
     |> assign(:post, Content.get_post!(id))}
  end

  defp format_datetime(nil), do: "Not scheduled"
  defp format_datetime(datetime), do: Calendar.strftime(datetime, "%d %b %Y")

  defp paragraphs(nil), do: []

  defp paragraphs(text) when is_binary(text) do
    text
    |> String.split(~r/\n\s*\n/, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp author_email(%{author: %{email: email}}), do: email
  defp author_email(_post), do: "No author"
end
