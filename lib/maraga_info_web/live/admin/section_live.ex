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
    page_home: %{
      title: "Home",
      subtitle: "Homepage hero, campaign framing, calls to action, and footer copy.",
      description:
        "Use this section as the home for future homepage blocks, including the hero message, featured stories, and supporter prompts."
    },
    page_about: %{
      title: "About Us",
      subtitle: "Static copy for biography, movement context, and organisational background.",
      description:
        "This placeholder is ready for structured editing of the About menu items such as David Maraga and UGM Party."
    },
    page_agenda: %{
      title: "Our Agenda",
      subtitle: "Campaign pillars, manifesto summaries, and issue-based landing sections.",
      description:
        "This area can grow into a page builder for manifesto summaries and policy landing pages."
    },
    page_resources: %{
      title: "Resources",
      subtitle: "Navigation and supporting content for posts, newsletters, and archive pages.",
      description:
        "This placeholder covers the public Resources menu, including archive labels and supporting descriptions."
    },
    page_press: %{
      title: "Press",
      subtitle: "Messaging, archive intros, and supporting copy for the press hub.",
      description:
        "Future iterations can manage the press landing page and the copy shown above press releases and media invitations."
    },
    page_shop: %{
      title: "Shop",
      subtitle: "Merchandising callouts and supporting copy for the external campaign shop.",
      description:
        "This slot is ready for shop-related messaging, banners, and future fundraising tie-ins."
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
      <.admin_empty_state title={@page_title <> " editor coming soon"} description={@description} />
    </.admin_shell>
    """
  end
end
