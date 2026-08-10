defmodule MaragaInfoWeb.BlogLive.Show do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfo.Content.Post
  alias MaragaInfoWeb.RichText
  alias MaragaInfoWeb.Seo
  alias MaragaInfoWeb.Uploads

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _uri, socket) do
    case Content.get_published_post_by_slug(slug) do
      nil ->
        {:noreply, push_navigate(socket, to: ~p"/")}

      post ->
        {previous_post, next_post} = Content.adjacent_published_posts(post)

        {:noreply,
         assign(socket,
           page_title: "#{post.title} | #{Seo.site_name()}",
           page_description: post.seo_description,
           canonical_url: Seo.article_url(post.slug),
           page_image: post.image_url,
           page_type: "article",
           page_published_time: iso8601(post.published_at),
           page_modified_time: iso8601(post.updated_at),
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
      <.site_header base_path="/" />

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

            <div class="mt-6 flex flex-wrap items-center gap-3 text-sm font-semibold uppercase tracking-[0.18em] text-grayink">
              <span>{format_date(@post.published_at)}</span>
              <span :if={@post.author} class="text-crimson">By {@post.author.email}</span>
            </div>
          </div>

          <div
            :if={@post.image_url}
            class="mx-auto mt-12 max-w-[1048px] overflow-hidden rounded-[8px] shadow-[0_18px_55px_rgba(15,30,80,0.12)]"
          >
            <img
              src={@post.image_url}
              alt={@post.title}
              class="mx-auto max-h-[760px] w-full object-contain"
            />
          </div>

          <div class="mx-auto mt-12 max-w-[760px] space-y-12 text-[1.12rem] leading-9 text-ink">
            <div
              :if={Post.canva_embed_src(@post.canva_embed_url)}
              class="overflow-hidden rounded-[8px] bg-white shadow-[0_12px_40px_rgba(15,30,80,0.1)] lg:-mx-[144px]"
            >
              <div class="relative w-full bg-white" style="padding-top: 141.42%;">
                <iframe
                  src={Post.canva_embed_src(@post.canva_embed_url)}
                  class="absolute inset-0 h-full w-full bg-white"
                  loading="lazy"
                  allowfullscreen
                >
                </iframe>
              </div>
            </div>

            <section :for={section <- @post.sections} :if={@post.sections != []} class="space-y-6">
              <h2
                :if={present?(section.heading)}
                class="font-head text-[2.2rem] uppercase leading-none tracking-[0.02em] text-blueink"
              >
                {section.heading}
              </h2>

              <div :if={present?(section.body)} class="rich-content">{render_body(section.body)}</div>

              <div :if={section.image_urls != []} class="space-y-6 sm:space-y-0">
                <div class={[
                  "grid gap-4",
                  length(section.image_urls) > 1 && "sm:grid-cols-2"
                ]}>
                  <div :for={url <- section.image_urls} class={Uploads.pdf?(url) && "sm:col-span-2"}>
                    <div
                      :if={Uploads.pdf?(url)}
                      class="overflow-hidden rounded-[8px] border border-[#dfe4ec] bg-[#f8f9fb] shadow-[0_12px_40px_rgba(15,30,80,0.08)]"
                    >
                      <iframe
                        src={url}
                        title={"PDF document for #{section.heading || @post.title}"}
                        class="h-[80vh] min-h-[640px] w-full bg-white"
                      >
                      </iframe>
                      <div class="flex justify-end border-t border-[#dfe4ec] px-4 py-3">
                        <a
                          href={url}
                          target="_blank"
                          rel="noopener noreferrer"
                          class="inline-flex items-center gap-2 text-sm font-semibold text-blueink transition hover:text-crimson"
                        >
                          Open PDF in a new tab
                          <.icon name="hero-arrow-top-right-on-square-mini" class="h-4 w-4" />
                        </a>
                      </div>
                    </div>
                    <img
                      :if={!Uploads.pdf?(url)}
                      src={url}
                      alt={section.heading || @post.title}
                      class="w-full rounded-[8px] object-cover object-[center_30%] shadow-[0_12px_40px_rgba(15,30,80,0.1)]"
                    />
                  </div>
                </div>
              </div>
            </section>

            <section :if={@post.sections == [] && present?(@post.body)} class="space-y-6">
              <div class="rich-content">{render_body(@post.body)}</div>
            </section>

            <.share_bar url={@canonical_url} title={@post.title} />
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

  defp render_body(text), do: RichText.render(text)

  defp present?(nil), do: false
  defp present?(value) when is_binary(value), do: String.trim(value) != ""

  defp format_date(nil), do: "Draft"
  defp format_date(%DateTime{} = published_at), do: Calendar.strftime(published_at, "%b %-d, %Y")

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = value), do: DateTime.to_iso8601(value)
end
