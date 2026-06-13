defmodule MaragaInfoWeb.BlogLive.Show do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Blog
  alias MaragaInfoWeb.Seo

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _uri, socket) do
    case Blog.get_post(slug) do
      nil ->
        {:noreply, push_navigate(socket, to: ~p"/")}

      post ->
        {previous_post, next_post} = Blog.adjacent_posts(slug)

        {:noreply,
         assign(socket,
           page_title: "#{post.title} | #{Seo.site_name()}",
           page_description: post.seo_description,
           canonical_url: Seo.article_url(post.slug),
           page_image: post.image,
           page_type: "article",
           page_published_time: post.iso_date,
           page_modified_time: post.iso_date,
           structured_data: Seo.article_structured_data(post),
           post: post,
           previous_post: previous_post,
           next_post: next_post
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white">
      <.site_header />

      <main class="px-4 pb-24 pt-16 sm:px-6 lg:px-8">
        <article class="mx-auto max-w-[1048px]">
          <div class="mx-auto max-w-[760px]">
            <a
              href={~p"/"}
              class="inline-flex items-center gap-2 font-head text-sm uppercase tracking-[0.18em] text-crimson transition hover:text-blueink"
            >
              <.icon name="hero-arrow-left-mini" class="h-4 w-4" /> Back to homepage
            </a>

            <div class="mt-8 inline-flex rounded-[6px] bg-crimson px-4 py-2 font-head text-sm uppercase tracking-[0.16em] text-white">
              {@post.category}
            </div>

            <h1 class="mt-8 font-head text-[3rem] uppercase leading-[0.96] tracking-[0.02em] text-blueink sm:text-[4.4rem]">
              {@post.title}
            </h1>

            <p class="mt-6 text-sm font-semibold uppercase tracking-[0.18em] text-grayink">
              {@post.date}
            </p>
          </div>

          <div class="mx-auto mt-12 max-w-[1048px] overflow-hidden rounded-[8px] shadow-[0_18px_55px_rgba(15,30,80,0.12)]">
            <img
              src={@post.image}
              alt={@post.title}
              class="h-[260px] w-full object-cover sm:h-[420px] lg:h-[560px]"
            />
          </div>

          <div class="mx-auto mt-12 max-w-[760px] space-y-12 text-[1.12rem] leading-9 text-ink">
            <p>{@post.intro}</p>

            <section :for={section <- @post.sections} class="space-y-5">
              <h2 class="font-head text-[2.2rem] uppercase leading-none tracking-[0.02em] text-blueink">
                {section.heading}
              </h2>
              <p>{section.body}</p>
            </section>
          </div>

          <div class="mx-auto mt-20 grid max-w-[760px] grid-cols-[1fr_auto_1fr] items-center gap-4 border-t border-[#e8ebf1] pt-10 text-grayink">
            <.post_nav_card post={@previous_post} direction={:previous} />

            <a
              href="/#news"
              class="flex h-14 w-14 items-center justify-center rounded-full border border-[#dfe4ec] text-grayink transition hover:border-blueink hover:text-blueink"
              aria-label="Return to article list"
            >
              <span class="grid grid-cols-2 gap-1">
                <span class="h-2.5 w-2.5 rounded-[2px] bg-current"></span>
                <span class="h-2.5 w-2.5 rounded-[2px] bg-current"></span>
                <span class="h-2.5 w-2.5 rounded-[2px] bg-current"></span>
                <span class="h-2.5 w-2.5 rounded-[2px] bg-current"></span>
              </span>
            </a>

            <.post_nav_card post={@next_post} direction={:next} />
          </div>
        </article>
      </main>

      <.site_footer base_path={~p"/"} />
    </div>
    """
  end

  defp site_header(assigns) do
    ~H"""
    <header class="border-b border-slate-200 bg-blueink">
      <div class="mx-auto flex w-full max-w-container items-center justify-between gap-6 px-4 py-5 lg:px-6">
        <a href={~p"/"} class="flex items-center gap-3">
          <img src="/images/logo.png" alt="David Maraga Info logo" class="h-10 w-auto rounded-sm" />
          <div class="font-head text-lg uppercase tracking-[0.14em] text-white">
            David Maraga Info
          </div>
        </a>

        <nav class="hidden items-center gap-6 lg:flex">
          <a
            href="/#profile"
            class="font-head text-sm uppercase tracking-[0.18em] text-white transition hover:text-crimson"
          >
            About
          </a>
          <a
            href="/#news"
            class="font-head text-sm uppercase tracking-[0.18em] text-white transition hover:text-crimson"
          >
            Latest News
          </a>
          <a
            href="/#timeline"
            class="font-head text-sm uppercase tracking-[0.18em] text-white transition hover:text-crimson"
          >
            Timeline
          </a>
        </nav>
      </div>
    </header>
    """
  end

  attr :post, :map, default: nil
  attr :direction, :atom, values: [:previous, :next], required: true

  defp post_nav_card(%{post: nil} = assigns) do
    ~H"""
    <div class={[
      "min-h-[72px]",
      @direction == :next && "text-right"
    ]}>
    </div>
    """
  end

  defp post_nav_card(assigns) do
    ~H"""
    <a
      href={~p"/blog/#{@post.slug}"}
      class={[
        "group min-h-[72px] transition hover:text-blueink",
        @direction == :next && "text-right"
      ]}
    >
      <div class="flex items-center gap-3 text-[0.95rem]">
        <span :if={@direction == :previous} class="text-blueink transition group-hover:-translate-x-1">
          <.icon name="hero-arrow-left-mini" class="h-5 w-5" />
        </span>
        <span class="font-body text-[0.95rem] text-grayink">
          {if @direction == :previous, do: "Prev post", else: "Next post"}
        </span>
        <span :if={@direction == :next} class="text-blueink transition group-hover:translate-x-1">
          <.icon name="hero-arrow-right-mini" class="h-5 w-5" />
        </span>
      </div>

      <div class="mt-3 font-head text-[1.1rem] uppercase leading-6 tracking-[0.02em] text-grayink transition group-hover:text-blueink">
        {@post.title}
      </div>
    </a>
    """
  end
end
