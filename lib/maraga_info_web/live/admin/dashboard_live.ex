defmodule MaragaInfoWeb.Admin.DashboardLive do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content

  @impl true
  def mount(_params, _session, socket) do
    posts = Content.list_posts()

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:page_subtitle, "An overview of your published and draft stories.")
     |> assign(:recent_posts, Enum.take(posts, 5))
     |> assign(:stats, dashboard_stats(posts))}
  end

  @impl true
  def handle_params(_params, url, socket) do
    {:noreply, assign(socket, :current_path, URI.parse(url).path)}
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
      <:actions>
        <.link
          navigate={~p"/admin/blogs/new"}
          class="inline-flex items-center gap-2 rounded-lg bg-blueink px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blueink/90"
        >
          <.icon name="hero-plus-mini" class="h-4 w-4" /> New post
        </.link>
      </:actions>

      <div class="space-y-6">
        <section class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <.admin_stat title="Total" value={Integer.to_string(@stats.total)} hint="All posts" />
          <.admin_stat
            title="Published"
            value={Integer.to_string(@stats.published)}
            hint="Live on the site"
            tone="accent"
          />
          <.admin_stat title="Drafts" value={Integer.to_string(@stats.drafts)} hint="In progress" />
          <.admin_stat
            title="Featured"
            value={Integer.to_string(@stats.featured)}
            hint="On homepage"
          />
        </section>

        <.admin_panel title="Recent posts" subtitle="Your latest stories.">
          <:actions>
            <.link
              navigate={~p"/admin/blogs"}
              class="text-sm font-medium text-blueink hover:underline"
            >
              View all
            </.link>
          </:actions>

          <div :if={@recent_posts != []} class="divide-y divide-zinc-100">
            <div
              :for={post <- @recent_posts}
              class="flex items-center justify-between gap-4 py-3 first:pt-0 last:pb-0"
            >
              <div class="min-w-0">
                <p class="truncate font-medium text-zinc-900">{post.title}</p>
                <p class="mt-0.5 text-sm text-zinc-500">
                  {post.category}
                  <span :if={post.published_at}>· {format_date(post.published_at)}</span>
                </p>
              </div>
              <div class="flex shrink-0 items-center gap-3">
                <.admin_badge
                  tone={if(post.status == :published, do: "published", else: "draft")}
                  label={to_string(post.status)}
                />
                <.link
                  navigate={~p"/admin/blogs/#{post}/edit"}
                  class="text-sm font-medium text-blueink hover:underline"
                >
                  Edit
                </.link>
              </div>
            </div>
          </div>

          <.admin_empty_state
            :if={@recent_posts == []}
            title="No posts yet"
            description="Start by adding the first article for the site."
            link={~p"/admin/blogs/new"}
            link_label="Create first post"
          />
        </.admin_panel>
      </div>
    </.admin_shell>
    """
  end

  defp dashboard_stats(posts) do
    Enum.reduce(posts, %{total: length(posts), published: 0, drafts: 0, featured: 0}, fn post,
                                                                                         acc ->
      acc
      |> increment_if(:featured, post.is_featured)
      |> increment_if(:published, post.status == :published)
      |> increment_if(:drafts, post.status == :draft)
    end)
  end

  defp increment_if(map, key, true), do: Map.update!(map, key, &(&1 + 1))
  defp increment_if(map, _key, false), do: map

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%d %b %Y")
  end
end
