defmodule MaragaInfoWeb.NewsLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfo.Content.Post
  alias MaragaInfoWeb.Seo

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "News | #{Seo.site_name()}")
     |> assign(
       :page_description,
       "The latest news, campaign updates and policy positions from David Maraga's 2027 campaign."
     )
     |> assign(:canonical_url, Seo.site_url() <> "/news")
     |> assign(:categories, Content.list_published_post_categories(scope: :posts))}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    category = Map.get(params, "category", "all")

    {:noreply,
     socket
     |> assign(:active_category, category)
     |> load_posts(category)}
  end

  @impl true
  def handle_event("filter", %{"category" => category}, socket) do
    {:noreply,
     socket
     |> assign(:active_category, category)
     |> load_posts(category)}
  end

  defp load_posts(socket, category) do
    assign(socket, :posts, Content.list_published_posts(scope: :posts, category: category))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white">
      <.site_header base_path="/" />

      <section
        class="relative overflow-hidden bg-cover"
        style="background-position: center 35%; background-image: url('/images/maraga-town.jpg');"
      >
        <div class="absolute inset-0 bg-blueink/70"></div>
        <div class="relative z-10 mx-auto flex min-h-[42vh] w-full max-w-container flex-col items-center justify-center px-4 py-24 text-center lg:px-6">
          <h3 class="font-serifi text-2xl italic text-white">David Maraga · Kenya 2027</h3>
          <h1 class="mt-3 font-head text-4xl font-semibold uppercase tracking-[3px] text-white md:text-6xl lg:text-7xl">
            Latest News
          </h1>
        </div>
      </section>

      <section class="bg-ghost py-16">
        <div class="mx-auto max-w-container px-4">
          <div class="mb-10 flex flex-wrap items-center justify-between gap-4">
            <h2 class="font-head text-2xl uppercase tracking-[0.08em] text-blueink">
              All <span class="text-crimson">News</span>
            </h2>

            <div class="flex flex-wrap items-center gap-5">
              <.filter_tab label="All News" value="all" active={@active_category} />
              <.filter_tab
                :for={category <- @categories}
                label={category}
                value={category}
                active={@active_category}
              />
            </div>
          </div>

          <div
            :if={@posts == []}
            class="rounded-[8px] bg-white px-8 py-16 text-center shadow-[0_15px_40px_rgba(15,30,80,0.08)]"
          >
            <h3 class="font-head text-2xl uppercase tracking-[0.08em] text-blueink">
              No news here yet
            </h3>
            <p class="mx-auto mt-3 max-w-xl text-base leading-7 text-grayink">
              Posts published in the admin area will appear here automatically.
            </p>
          </div>

          <div :if={@posts != []} class="grid grid-cols-1 gap-7 md:grid-cols-2 lg:grid-cols-3">
            <.news_card :for={post <- @posts} item={post} />
          </div>
        </div>
      </section>

      <.site_footer base_path={~p"/"} />
    </div>
    """
  end

  attr :item, :map, required: true

  defp news_card(assigns) do
    ~H"""
    <article class="group flex flex-col overflow-hidden rounded-[5px] bg-white shadow-[0_15px_40px_rgba(15,30,80,0.08)]">
      <.link :if={@item.image_url} navigate={~p"/blog/#{@item.slug}"} class="block overflow-hidden">
        <img
          src={@item.image_url}
          alt={@item.title}
          loading="lazy"
          class="h-[260px] w-full object-cover object-[center_30%] transition duration-500 group-hover:scale-105"
        />
      </.link>

      <div class="flex flex-1 flex-col p-7">
        <div class="flex items-center gap-2 text-xs">
          <span class="font-bold uppercase tracking-[2px] text-crimson">
            {format_post_date(@item.published_at)}
          </span>
          <span class="text-grayink">|</span>
          <span class="font-bold uppercase tracking-[1px] text-grayink">
            {@item.category}
          </span>
        </div>
        <.link navigate={~p"/blog/#{@item.slug}"}>
          <h4 class="mt-3 font-head text-2xl uppercase tracking-[.5px] text-blueink transition hover:text-crimson">
            {@item.title}
          </h4>
        </.link>
        <div class="my-5 h-px w-full bg-[#e6e6e6]"></div>
        <p class="mt-0 text-base leading-7 text-grayink">
          {Post.summary(@item)}
        </p>
      </div>
    </article>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :active, :string, required: true

  defp filter_tab(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="filter"
      phx-value-category={@value}
      class={[
        "font-head text-sm font-semibold uppercase tracking-[0.12em] transition",
        @active == @value && "text-crimson",
        @active != @value && "text-blueink hover:text-crimson"
      ]}
    >
      {@label}
    </button>
    """
  end

  defp format_post_date(nil), do: "Draft"

  defp format_post_date(%DateTime{} = published_at),
    do: Calendar.strftime(published_at, "%b %-d, %Y")
end
