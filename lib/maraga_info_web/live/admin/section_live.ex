defmodule MaragaInfoWeb.Admin.SectionLive do
  use MaragaInfoWeb, :live_view

  @sections %{
    pages: %{
      title: "Pages",
      subtitle:
        "A clean place for editing static sections, landing pages, and campaign copy blocks.",
      description:
        "We can grow this into a structured page builder for homepage sections, about content, and fundraising pages."
    },
    settings: %{
      title: "Settings",
      subtitle: "Administrative preferences, access controls, and content publishing defaults.",
      description:
        "This is prepared for role management, SEO defaults, and broader CMS preferences as the admin grows."
    }
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, url, socket) do
    section = socket.assigns.live_action
    content = Map.fetch!(@sections, section)

    {:noreply,
     socket
     |> assign(:current_path, URI.parse(url).path)
     |> assign(:section, section)
     |> assign(:page_title, content.title)
     |> assign(:page_subtitle, content.subtitle)
     |> assign(:description, content.description)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell
      page_title={@page_title}
      page_subtitle={@page_subtitle}
      current_user={@current_user}
      current_path={@current_path}
    >
      <.admin_empty_state title={@page_title <> " coming soon"} description={@description} />
    </.admin_shell>
    """
  end
end
