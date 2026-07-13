defmodule MaragaInfoWeb.BlogLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfo.Content.Post
  alias MaragaInfoWeb.Seo

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Blog | #{Seo.site_name()}")
     |> assign(
       :page_description,
       "Long-form articles, reflections and perspectives from David Maraga's 2027 campaign."
     )
     |> assign(:canonical_url, Seo.site_url() <> "/blog")
     |> assign(:posts, Content.list_published_blogs(scope: :blogs))}
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
            Blog
          </h1>
        </div>
      </section>

      <section class="bg-ghost py-16">
        <div class="mx-auto max-w-container px-4">
          <div class="mb-10">
            <h2 class="font-head text-2xl uppercase tracking-[0.08em] text-blueink">
              From the <span class="text-crimson">Blog</span>
            </h2>
          </div>

          <div
            :if={@posts == []}
            class="rounded-[8px] bg-white px-8 py-16 text-center shadow-[0_15px_40px_rgba(15,30,80,0.08)]"
          >
            <h3 class="font-head text-2xl uppercase tracking-[0.08em] text-blueink">
              No blog posts yet
            </h3>
            <p class="mx-auto mt-3 max-w-xl text-base leading-7 text-grayink">
              Articles published under the Blog category in the admin area appear here automatically.
            </p>
          </div>

          <div :if={@posts != []} class="grid grid-cols-1 gap-7 md:grid-cols-2 lg:grid-cols-3">
            <.blog_card :for={post <- @posts} item={post} />
          </div>
        </div>
      </section>

      <.site_footer base_path={~p"/"} />
    </div>
    """
  end

  attr :item, :map, required: true

  defp blog_card(assigns) do
    ~H"""
    <article class="group flex flex-col overflow-hidden rounded-[5px] bg-white shadow-[0_15px_40px_rgba(15,30,80,0.08)]">
      <.link :if={@item.image_url} navigate={~p"/blog/#{@item.slug}"} class="block overflow-hidden">
        <img
          src={@item.image_url}
          alt={@item.title}
          loading="lazy"
          class="aspect-[3/2] w-full bg-white object-cover"
          style={Post.image_position_style(@item)}
        />
      </.link>

      <div class="flex flex-1 flex-col p-7">
        <div class="flex items-center gap-2 text-xs">
          <span class="font-bold uppercase tracking-[2px] text-crimson">
            {format_post_date(@item.published_at)}
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

  defp format_post_date(nil), do: "Draft"

  defp format_post_date(%DateTime{} = published_at),
    do: Calendar.strftime(published_at, "%b %-d, %Y")
end
