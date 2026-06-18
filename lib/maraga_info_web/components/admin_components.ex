defmodule MaragaInfoWeb.AdminComponents do
  use Phoenix.Component
  use Gettext, backend: MaragaInfoWeb.Gettext

  use Phoenix.VerifiedRoutes,
    endpoint: MaragaInfoWeb.Endpoint,
    router: MaragaInfoWeb.Router,
    statics: MaragaInfoWeb.static_paths()

  import MaragaInfoWeb.CoreComponents

  attr :page_title, :string, required: true
  attr :page_subtitle, :string, default: nil
  attr :current_user, :map, default: nil
  attr :current_path, :string, default: "/admin"
  slot :actions
  slot :inner_block, required: true

  def admin_shell(assigns) do
    assigns = assign(assigns, :navigation, navigation_items())

    ~H"""
    <div class="min-h-screen bg-zinc-50">
      <div class="mx-auto flex  gap-8 px-4 py-6 lg:px-8">
        <aside class="hidden w-60 shrink-0 lg:block">
          <div class="sticky top-6 space-y-6">
            <.link navigate={~p"/admin"} class="flex items-start gap-2.5">
              <img src={~p"/images/logo.png"} alt="Maraga Info" class="h-9  " />
            </.link>

            <nav class="space-y-0.5">
              <div :for={entry <- @navigation}>
                <p
                  :if={entry[:type] == :heading}
                  class="px-3 pb-1 pt-4 text-[11px] font-semibold uppercase tracking-[0.24em] text-zinc-400 first:pt-0"
                >
                  {entry.label}
                </p>
                <.admin_nav_link
                  :if={entry[:type] != :heading}
                  item={entry}
                  current_path={@current_path}
                />
              </div>
            </nav>

            <div class="border-t border-zinc-200 pt-4">
              <p class="truncate px-3 text-xs text-zinc-500">
                {@current_user && @current_user.email}
              </p>
              <div class="mt-2 flex flex-col gap-0.5">
                <.link
                  href={~p"/"}
                  class="rounded-lg px-3 py-2 text-sm text-zinc-600 transition hover:bg-zinc-100 hover:text-zinc-900"
                >
                  View site
                </.link>
                <.link
                  href={~p"/users/log_out"}
                  method="delete"
                  class="rounded-lg px-3 py-2 text-sm text-zinc-600 transition hover:bg-zinc-100 hover:text-zinc-900"
                >
                  Log out
                </.link>
              </div>
            </div>
          </div>
        </aside>

        <div class="min-w-0 flex-1 space-y-6">
          <header class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div class="min-w-0">
              <h1 class="text-2xl font-semibold tracking-tight text-zinc-900">{@page_title}</h1>
              <p :if={@page_subtitle} class="mt-1 max-w-2xl text-sm text-zinc-500">
                {@page_subtitle}
              </p>
            </div>
            <div :if={@actions != []} class="flex shrink-0 flex-wrap items-center gap-2">
              {render_slot(@actions)}
            </div>
          </header>

          <main>
            {render_slot(@inner_block)}
          </main>
        </div>
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :value, :string, required: true
  attr :hint, :string, default: nil
  attr :tone, :string, values: ~w(default accent), default: "default"

  def admin_stat(assigns) do
    ~H"""
    <div class={[
      "rounded-xl border p-5",
      @tone == "accent" && "border-blueink bg-blueink text-white",
      @tone == "default" && "border-zinc-200 bg-white"
    ]}>
      <p class={[
        "text-sm font-medium",
        @tone == "accent" && "text-white/80",
        @tone == "default" && "text-zinc-500"
      ]}>
        {@title}
      </p>
      <p class="mt-2 text-3xl font-semibold tracking-tight">{@value}</p>
      <p
        :if={@hint}
        class={[
          "mt-1 text-xs",
          @tone == "accent" && "text-white/70",
          @tone == "default" && "text-zinc-400"
        ]}
      >
        {@hint}
      </p>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  slot :actions
  slot :inner_block, required: true

  def admin_panel(assigns) do
    ~H"""
    <section class="rounded-xl border border-zinc-200 bg-white">
      <div class="flex flex-col gap-3 border-b border-zinc-100 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 class="text-base font-semibold text-zinc-900">{@title}</h2>
          <p :if={@subtitle} class="mt-0.5 text-sm text-zinc-500">{@subtitle}</p>
        </div>
        <div :if={@actions != []} class="flex flex-wrap items-center gap-2">
          {render_slot(@actions)}
        </div>
      </div>
      <div class="px-5 py-4">
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  attr :tone, :string, values: ~w(draft published neutral), default: "neutral"
  attr :label, :string, required: true

  def admin_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium capitalize",
      @tone == "published" && "bg-green-50 text-green-700 ring-1 ring-inset ring-green-600/20",
      @tone == "draft" && "bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-600/20",
      @tone == "neutral" && "bg-zinc-100 text-zinc-600"
    ]}>
      {@label}
    </span>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :link, :string, default: nil
  attr :link_label, :string, default: nil

  def admin_empty_state(assigns) do
    ~H"""
    <div class="rounded-xl border border-dashed border-zinc-300 px-6 py-12 text-center">
      <div class="mx-auto flex h-11 w-11 items-center justify-center rounded-full bg-zinc-100 text-zinc-500">
        <.icon name="hero-document-plus" class="h-5 w-5" />
      </div>
      <h3 class="mt-3 text-sm font-semibold text-zinc-900">{@title}</h3>
      <p class="mx-auto mt-1 max-w-md text-sm text-zinc-500">{@description}</p>
      <.link
        :if={@link && @link_label}
        navigate={@link}
        class="mt-4 inline-flex items-center rounded-lg bg-blueink px-4 py-2 text-sm font-semibold text-white transition hover:bg-blueink/90"
      >
        {@link_label}
      </.link>
    </div>
    """
  end

  attr :item, :map, required: true
  attr :current_path, :string, required: true

  defp admin_nav_link(assigns) do
    ~H"""
    <.link
      navigate={@item.href}
      class={[
        "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition",
        nav_active?(@current_path, @item.href) && "bg-blueink text-white",
        !nav_active?(@current_path, @item.href) &&
          "text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900"
      ]}
    >
      <.icon name={@item.icon} class="h-5 w-5" />
      {@item.label}
    </.link>
    """
  end

  defp navigation_items do
    [
      %{label: "Dashboard", href: ~p"/admin", icon: "hero-home"},
      %{type: :heading, label: "Content"},
      %{label: "Posts", href: ~p"/admin/posts", icon: "hero-document-text"},
      %{label: "Blogs", href: ~p"/admin/blogs", icon: "hero-pencil-square"},
      %{label: "Newsletters", href: ~p"/admin/newsletters", icon: "hero-newspaper"},
      %{label: "Press Releases", href: ~p"/admin/press-releases", icon: "hero-megaphone"},
      %{
        label: "Media Invitations",
        href: ~p"/admin/media-invitations",
        icon: "hero-envelope-open"
      },
      %{label: "Photos", href: ~p"/admin/media/photos", icon: "hero-photo"},
      %{label: "Videos", href: ~p"/admin/media/videos", icon: "hero-video-camera"},
      %{type: :heading, label: "Pages"},
      %{label: "Home", href: ~p"/admin/pages/home", icon: "hero-home-modern"},
      %{label: "About Us", href: ~p"/admin/pages/about", icon: "hero-user-circle"},
      %{label: "Our Agenda", href: ~p"/admin/pages/agenda", icon: "hero-clipboard-document-list"},
      %{label: "Resources", href: ~p"/admin/pages/resources", icon: "hero-book-open"},
      %{label: "Press", href: ~p"/admin/pages/press", icon: "hero-megaphone"},
      %{label: "Shop", href: ~p"/admin/pages/shop", icon: "hero-shopping-bag"},
      %{type: :heading, label: "Operations"},
      %{label: "Volunteers", href: ~p"/admin/volunteers", icon: "hero-users"},
      %{label: "Emails", href: ~p"/admin/emails", icon: "hero-envelope"},
      %{type: :heading, label: "System"},
      %{label: "Settings", href: ~p"/admin/settings", icon: "hero-cog-6-tooth"}
    ]
  end

  defp nav_active?(current_path, href) when href == "/admin", do: current_path == href

  defp nav_active?(current_path, href) do
    current_path == href or String.starts_with?(current_path, href <> "/")
  end
end
