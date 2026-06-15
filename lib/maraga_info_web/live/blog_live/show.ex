defmodule MaragaInfoWeb.BlogLive.Show do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfo.Content.Post
  alias MaragaInfoWeb.RichText
  alias MaragaInfoWeb.Seo

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

          <div class="mx-auto mt-12 max-w-[1048px] overflow-hidden rounded-[8px] shadow-[0_18px_55px_rgba(15,30,80,0.12)]">
            <img
              src={@post.image_url}
              alt={@post.title}
              class="h-[260px] w-full object-cover object-[center_30%] sm:h-[420px] lg:h-[560px]"
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

              <p :for={paragraph <- paragraphs(section.body)}>{format_inline(paragraph)}</p>

              <div :if={section.image_urls != []} class="space-y-6 sm:space-y-0">
                <div class={[
                  "grid gap-4",
                  length(section.image_urls) > 1 && "sm:grid-cols-2"
                ]}>
                  <img
                    :for={url <- section.image_urls}
                    src={url}
                    alt={section.heading || @post.title}
                    class="w-full rounded-[8px] object-cover object-[center_30%] shadow-[0_12px_40px_rgba(15,30,80,0.1)]"
                  />
                </div>
              </div>
            </section>

            <section :if={@post.sections == [] && present?(@post.body)} class="space-y-6">
              <h2 class="font-head text-[2.2rem] uppercase leading-none tracking-[0.02em] text-blueink">
                Full story
              </h2>

              <p :for={paragraph <- paragraphs(@post.body)}>{format_inline(paragraph)}</p>
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

  attr :url, :string, required: true
  attr :title, :string, required: true

  defp share_bar(assigns) do
    %{url: url, title: title} = assigns
    encoded_url = URI.encode_www_form(url)
    encoded_title = URI.encode_www_form(title)

    assigns =
      assign(assigns,
        facebook_url: "https://www.facebook.com/sharer/sharer.php?u=#{encoded_url}",
        x_url: "https://twitter.com/intent/tweet?url=#{encoded_url}&text=#{encoded_title}",
        whatsapp_url: "https://api.whatsapp.com/send?text=#{encoded_title}%20#{encoded_url}",
        linkedin_url: "https://www.linkedin.com/sharing/share-offsite/?url=#{encoded_url}",
        telegram_url: "https://t.me/share/url?url=#{encoded_url}&text=#{encoded_title}",
        email_url: "mailto:?subject=#{encoded_title}&body=#{encoded_url}"
      )

    ~H"""
    <div class="border-t border-[#e8ebf1] pt-10">
      <span class="font-head text-sm uppercase tracking-[0.18em] text-grayink">
        Share this story
      </span>

      <div class="mt-4 flex flex-wrap items-center gap-3">
        <a
          href={@facebook_url}
          target="_blank"
          rel="noopener noreferrer"
          aria-label="Share on Facebook"
          class="flex h-11 w-11 items-center justify-center rounded-full border border-[#dfe4ec] text-grayink transition hover:border-blueink hover:bg-blueink hover:text-white"
        >
          <svg class="h-5 w-5" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M22 12.06C22 6.5 17.52 2 12 2S2 6.5 2 12.06c0 5 3.66 9.15 8.44 9.94v-7.03H7.9v-2.9h2.54V9.85c0-2.51 1.49-3.9 3.78-3.9 1.09 0 2.24.2 2.24.2v2.46h-1.26c-1.24 0-1.63.78-1.63 1.57v1.88h2.78l-.44 2.9h-2.34V22c4.78-.79 8.43-4.94 8.43-9.94Z" />
          </svg>
        </a>

        <a
          href={@x_url}
          target="_blank"
          rel="noopener noreferrer"
          aria-label="Share on X"
          class="flex h-11 w-11 items-center justify-center rounded-full border border-[#dfe4ec] text-grayink transition hover:border-blueink hover:bg-blueink hover:text-white"
        >
          <svg class="h-[18px] w-[18px]" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24h-6.66l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231 5.45-6.231Zm-1.161 17.52h1.833L7.084 4.126H5.117l11.966 15.644Z" />
          </svg>
        </a>

        <a
          href={@whatsapp_url}
          target="_blank"
          rel="noopener noreferrer"
          aria-label="Share on WhatsApp"
          class="flex h-11 w-11 items-center justify-center rounded-full border border-[#dfe4ec] text-grayink transition hover:border-blueink hover:bg-blueink hover:text-white"
        >
          <svg class="h-5 w-5" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M17.47 14.38c-.3-.15-1.76-.87-2.03-.97-.27-.1-.47-.15-.67.15-.2.3-.77.97-.94 1.17-.17.2-.35.22-.65.07-.3-.15-1.26-.46-2.4-1.48-.89-.79-1.49-1.77-1.66-2.07-.17-.3-.02-.46.13-.61.13-.13.3-.35.45-.52.15-.17.2-.3.3-.5.1-.2.05-.37-.02-.52-.07-.15-.67-1.62-.92-2.22-.24-.58-.49-.5-.67-.51-.17-.01-.37-.01-.57-.01-.2 0-.52.07-.8.37-.27.3-1.04 1.02-1.04 2.48 0 1.46 1.07 2.88 1.22 3.08.15.2 2.1 3.2 5.08 4.49.71.31 1.26.49 1.69.62.71.23 1.36.2 1.87.12.57-.08 1.76-.72 2.01-1.41.25-.7.25-1.29.17-1.42-.07-.13-.27-.2-.57-.35ZM12.04 21.5h-.01a9.4 9.4 0 0 1-4.79-1.31l-.34-.2-3.56.93.95-3.47-.22-.36a9.38 9.38 0 0 1-1.44-5.01c0-5.18 4.22-9.4 9.41-9.4 2.51 0 4.87.98 6.64 2.76a9.34 9.34 0 0 1 2.75 6.65c0 5.18-4.22 9.41-9.4 9.41Zm8-17.41A11.32 11.32 0 0 0 12.04.75C5.8.75.72 5.83.72 12.07c0 1.99.52 3.94 1.51 5.66L.63 23.25l5.65-1.48a11.3 11.3 0 0 0 5.76 1.47h.01c6.23 0 11.31-5.08 11.32-11.32a11.25 11.25 0 0 0-3.32-8.01Z" />
          </svg>
        </a>

        <a
          href={@linkedin_url}
          target="_blank"
          rel="noopener noreferrer"
          aria-label="Share on LinkedIn"
          class="flex h-11 w-11 items-center justify-center rounded-full border border-[#dfe4ec] text-grayink transition hover:border-blueink hover:bg-blueink hover:text-white"
        >
          <svg class="h-5 w-5" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M20.45 20.45h-3.56v-5.57c0-1.33-.02-3.04-1.85-3.04-1.85 0-2.13 1.45-2.13 2.94v5.67H9.35V9h3.42v1.56h.05c.48-.9 1.64-1.85 3.37-1.85 3.6 0 4.27 2.37 4.27 5.46v6.28ZM5.34 7.43a2.07 2.07 0 1 1 0-4.14 2.07 2.07 0 0 1 0 4.14Zm1.78 13.02H3.55V9h3.57v11.45ZM22.22 0H1.77C.79 0 0 .77 0 1.73v20.54C0 23.22.79 24 1.77 24h20.45c.98 0 1.78-.78 1.78-1.73V1.73C24 .77 23.2 0 22.22 0Z" />
          </svg>
        </a>

        <a
          href={@telegram_url}
          target="_blank"
          rel="noopener noreferrer"
          aria-label="Share on Telegram"
          class="flex h-11 w-11 items-center justify-center rounded-full border border-[#dfe4ec] text-grayink transition hover:border-blueink hover:bg-blueink hover:text-white"
        >
          <svg class="h-5 w-5" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M23.91 3.79 20.3 20.84c-.25 1.21-.98 1.5-2 .94l-5.5-4.07-2.66 2.57c-.3.3-.55.56-1.1.56l.38-5.56 10.07-9.1c.44-.39-.1-.61-.68-.22L6.27 13.5 .89 11.8c-1.17-.37-1.2-1.17.24-1.73L22.4 1.85c.97-.36 1.82.22 1.5 1.94Z" />
          </svg>
        </a>

        <a
          href={@email_url}
          aria-label="Share via email"
          class="flex h-11 w-11 items-center justify-center rounded-full border border-[#dfe4ec] text-grayink transition hover:border-blueink hover:bg-blueink hover:text-white"
        >
          <.icon name="hero-envelope" class="h-5 w-5" />
        </a>

        <button
          type="button"
          id="copy-link-button"
          phx-hook="CopyLink"
          data-url={@url}
          aria-label="Copy link"
          class="flex h-11 items-center gap-2 rounded-full border border-[#dfe4ec] px-4 text-sm font-semibold uppercase tracking-[0.14em] text-grayink transition hover:border-blueink hover:bg-blueink hover:text-white"
        >
          <.icon name="hero-link" class="h-5 w-5" />
          <span data-copy-label>Copy link</span>
        </button>
      </div>
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

  defp paragraphs(text), do: RichText.paragraphs(text)

  defp format_inline(text), do: RichText.format_inline(text)

  defp present?(nil), do: false
  defp present?(value) when is_binary(value), do: String.trim(value) != ""

  defp format_date(nil), do: "Draft"
  defp format_date(%DateTime{} = published_at), do: Calendar.strftime(published_at, "%b %-d, %Y")

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = value), do: DateTime.to_iso8601(value)
end
