defmodule MaragaInfoWeb.SiteComponents do
  use Phoenix.Component

  alias MaragaInfo.Content
  alias MaragaInfo.Content.Post
  alias MaragaInfoWeb.Seo
  alias Phoenix.LiveView.JS
  import MaragaInfoWeb.CoreComponents

  @social_links [
    %{name: "x", href: "https://x.com/dkmaraga", label: "X"},
    %{name: "instagram", href: "https://www.instagram.com/maraga2027", label: "Instagram"},
    %{name: "youtube", href: "https://www.youtube.com/@dkmaraga", label: "YouTube"},
    %{name: "facebook", href: "https://www.facebook.com/Maraga2027", label: "Facebook"},
    %{name: "tiktok", href: "https://www.tiktok.com/@maraga2027", label: "TikTok"}
  ]

  attr :item, :map, required: true

  def post_card_preview(assigns) do
    assigns =
      assigns
      |> assign(:has_image?, present?(assigns.item.image_url))
      |> assign(:preview_text, card_preview_text(assigns.item))

    ~H"""
    <.link
      navigate={"/blog/#{@item.slug}"}
      class="block overflow-hidden"
      aria-label={"Read #{@item.title}"}
    >
      <img
        :if={@has_image?}
        src={@item.image_url}
        alt={@item.title}
        loading="lazy"
        class="aspect-[3/2] w-full bg-white object-cover transition duration-300 group-hover:scale-[1.02]"
        style={Post.image_position_style(@item)}
      />
      <div
        :if={!@has_image?}
        class="relative flex aspect-[3/2] w-full flex-col justify-between overflow-hidden bg-blueink px-7 py-8 text-white"
      >
        <div class="absolute -right-10 -top-12 h-40 w-40 rounded-full border border-white/10"></div>
        <div class="absolute -bottom-16 -left-10 h-44 w-44 rounded-full bg-crimson/15"></div>
        <.icon name="hero-document-text" class="relative h-8 w-8 text-crimson" />
        <p class="relative line-clamp-4 font-serifi text-xl leading-8 md:text-2xl">
          {@preview_text}
        </p>
        <span class="relative font-head text-xs font-bold uppercase tracking-[0.18em] text-white/70">
          Read more
        </span>
      </div>
    </.link>
    """
  end

  defp card_preview_text(post) do
    case Post.summary(post, 170) do
      "" -> post.title || "Open this post to read the full text or attached document."
      summary -> summary
    end
  end

  defp present?(nil), do: false
  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_value), do: false

  attr :base_path, :string, default: ""

  def site_header(assigns) do
    assigns =
      assigns
      |> assign(:social_links, @social_links)
      |> assign_new(:news_categories, fn ->
        Content.post_categories(:posts)
      end)
      |> assign_new(:nav_links, fn -> Content.list_visible_nav_links() end)

    assigns =
      assigns
      |> assign(:left_nav_links, Map.get(assigns.nav_links, "left", []))
      |> assign(:right_nav_links, Map.get(assigns.nav_links, "right", []))

    assigns =
      assign(
        assigns,
        :search_items,
        build_search_items(assigns.base_path, assigns.news_categories)
      )

    ~H"""
    <header class="relative z-30 w-full bg-blueink">
      <input id="nav-toggle" type="checkbox" class="peer hidden" />

      <div class="relative mx-auto flex w-full max-w-container items-center justify-between gap-4 px-4 py-3 lg:px-6">
        <nav class="hidden min-w-0 flex-1 items-center gap-5 lg:flex xl:gap-6">
          <a
            href={section_href(@base_path, "top")}
            class="whitespace-nowrap font-head text-[15px] font-medium uppercase tracking-wide text-crimson"
          >
            Home
          </a>

          <.nav_entry :for={nav_link <- @left_nav_links} nav_link={nav_link} />
        </nav>

        <a href={section_href(@base_path, "top")} class="flex shrink-0 items-center gap-2 lg:hidden">
          <img
            src="/images/PHOTO-2026-06-14-22-19-17.jpg"
            alt="David Maraga logo"
            class="h-12 w-auto shrink-0"
          />
          <img src="/images/ugm-logo.png" alt="UGM party logo" class="h-10 w-auto shrink-0" />
        </a>

        <a
          href={section_href(@base_path, "top")}
          class="absolute left-1/2 top-0 z-50 hidden -translate-x-1/2 flex-row items-center gap-2.5 rounded-b-md bg-crimson px-5 pb-3 pt-2 shadow-lg lg:flex"
        >
          <img src="/images/logo.png" alt="Maraga '27" class="h-11 w-auto shrink-0" />
          <span aria-hidden="true" class="h-8 w-px bg-blueink/25"></span>
          <img
            src="/images/ugm-logo.png"
            alt="United Green Movement Party logo"
            class="h-9 w-auto shrink-0 rounded-[3px] bg-white p-0.5"
          />
        </a>

        <%!-- Reserves the centre badge's width so the nav links either side can
        never slide underneath it. Mirrors the badge markup exactly. --%>
        <div
          aria-hidden="true"
          class="pointer-events-none hidden shrink-0 flex-row items-center gap-2.5 px-5 opacity-0 lg:flex"
        >
          <img src="/images/logo.png" alt="" class="h-11 w-auto shrink-0" />
          <span class="h-8 w-px"></span>
          <img src="/images/ugm-logo.png" alt="" class="h-9 w-auto shrink-0 p-0.5" />
        </div>

        <div class="flex min-w-0 flex-1 items-center justify-end gap-4 xl:gap-6">
          <nav class="hidden items-center gap-5 lg:flex xl:gap-6">
            <.nav_entry :for={nav_link <- @right_nav_links} nav_link={nav_link} />
            <button
              type="button"
              phx-click={open_search_modal()}
              aria-label="Search the site"
              title="Search the site"
              class="inline-flex h-9 w-9 items-center justify-center rounded-full border border-white/30 text-white transition hover:border-crimson hover:text-crimson"
            >
              <.icon name="hero-magnifying-glass-mini" class="h-5 w-5" />
            </button>
          </nav>

          <.link
            navigate="/admin"
            aria-label="Admin"
            title="Admin"
            class="hidden h-9 w-9 items-center justify-center rounded-full border border-white/30 text-white transition hover:border-crimson hover:text-crimson lg:flex"
          >
            <svg
              class="h-5 w-5"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
              <circle cx="12" cy="7" r="4" />
            </svg>
          </.link>

          <label
            for="nav-toggle"
            aria-label="Toggle navigation menu"
            class="flex h-9 w-9 cursor-pointer items-center justify-center rounded-full border border-white/30 text-white transition hover:border-crimson hover:text-crimson lg:hidden"
          >
            <svg
              class="h-5 w-5"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <line x1="4" y1="6" x2="20" y2="6" />
              <line x1="4" y1="12" x2="20" y2="12" />
              <line x1="4" y1="18" x2="20" y2="18" />
            </svg>
          </label>
        </div>
      </div>

      <nav class="hidden flex-col gap-1 bg-blueink px-6 pb-6 pt-2 shadow-xl peer-checked:flex lg:!hidden">
        <a
          href={section_href(@base_path, "top")}
          class="py-1 font-head text-[15px] font-medium uppercase tracking-wide text-crimson"
        >
          Home
        </a>

        <.mobile_nav_entry :for={nav_link <- @left_nav_links} nav_link={nav_link} />
        <.mobile_nav_entry :for={nav_link <- @right_nav_links} nav_link={nav_link} />

        <button
          type="button"
          onclick="document.getElementById('nav-toggle').checked = false"
          phx-click={open_search_modal()}
          class="flex items-center gap-2 py-1 font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
        >
          <.icon name="hero-magnifying-glass-mini" class="h-4 w-4" /> Search
        </button>
      </nav>

      <.modal
        id="site-search-modal"
        on_cancel={JS.dispatch("site-search:close", to: "#site-search-panel")}
      >
        <div id="site-search-panel" phx-hook="SiteSearchModal">
          <div class="border-b border-zinc-100 pb-5">
            <p class="font-head text-[11px] uppercase tracking-[0.24em] text-crimson">Search</p>
            <h2 class="mt-2 font-head text-3xl uppercase tracking-[0.06em] text-blueink">
              Find Your Way Around
            </h2>
            <p class="mt-3 text-sm leading-6 text-grayink">
              Start typing and jump straight to a page, story, event, or homepage section.
            </p>
          </div>

          <div class="mt-6">
            <label for="site-search-input" class="sr-only">Search the site</label>
            <div class="relative">
              <span class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4 text-grayink">
                <.icon name="hero-magnifying-glass-mini" class="h-5 w-5" />
              </span>
              <input
                id="site-search-input"
                type="search"
                placeholder="Search pages, content, and sections"
                autocomplete="off"
                data-search-input
                class="w-full rounded-xl border border-zinc-200 bg-zinc-50 py-3 pl-12 pr-4 text-base text-blueink outline-none transition focus:border-crimson focus:bg-white"
              />
            </div>

            <div class="mt-4 flex items-center justify-between gap-3 text-xs uppercase tracking-[0.16em] text-grayink">
              <span data-search-count>{length(@search_items)} results</span>
              <span>Press esc to close</span>
            </div>
          </div>

          <div class="mt-6 max-h-[55vh] overflow-y-auto pr-1">
            <p
              data-search-empty
              class="hidden rounded-xl bg-ghost px-4 py-6 text-center text-sm text-grayink"
            >
              No matching pages yet. Try another keyword.
            </p>

            <div class="grid gap-3">
              <div
                :for={item <- @search_items}
                data-search-item
                data-search-text={item.search_text}
                class="rounded-xl border border-zinc-100 bg-white transition hover:border-crimson/40 hover:bg-ghost"
              >
                <a
                  href={item.href}
                  target={if item.external?, do: "_blank", else: nil}
                  rel={if item.external?, do: "noopener", else: nil}
                  class="block px-4 py-4"
                >
                  <div class="flex items-center justify-between gap-3">
                    <div>
                      <p class="font-head text-[11px] uppercase tracking-[0.18em] text-crimson">
                        {item.group}
                      </p>
                      <h3 class="mt-1 font-head text-lg uppercase tracking-[0.04em] text-blueink">
                        {item.title}
                      </h3>
                    </div>
                    <.icon name="hero-arrow-right-mini" class="h-5 w-5 shrink-0 text-grayink" />
                  </div>
                  <p :if={item.description} class="mt-2 text-sm leading-6 text-grayink">
                    {item.description}
                  </p>
                </a>
              </div>
            </div>
          </div>
        </div>
      </.modal>
    </header>
    """
  end

  attr :nav_link, :map, required: true

  defp nav_entry(%{nav_link: %{children: [_ | _]}} = assigns) do
    ~H"""
    <.nav_dropdown label={@nav_link.label}>
      <.nav_link_href
        :for={child <- @nav_link.children}
        href={child.href}
        class="text-[15px] text-ink transition hover:text-crimson"
      >
        {child.label}
      </.nav_link_href>
    </.nav_dropdown>
    """
  end

  defp nav_entry(assigns) do
    ~H"""
    <.nav_link_href
      href={@nav_link.href}
      class="whitespace-nowrap font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
    >
      {@nav_link.label}
    </.nav_link_href>
    """
  end

  attr :nav_link, :map, required: true

  defp mobile_nav_entry(%{nav_link: %{children: [_ | _]}} = assigns) do
    ~H"""
    <p class="pt-3 font-head text-[12px] font-semibold uppercase tracking-[0.2em] text-white/60">
      {@nav_link.label}
    </p>
    <.nav_link_href
      :for={child <- @nav_link.children}
      href={child.href}
      class="py-1 pl-3 text-[14px] text-white/85 transition hover:text-crimson"
    >
      {child.label}
    </.nav_link_href>
    """
  end

  defp mobile_nav_entry(assigns) do
    ~H"""
    <.nav_link_href
      href={@nav_link.href}
      class="py-1 pt-3 font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
    >
      {@nav_link.label}
    </.nav_link_href>
    """
  end

  attr :href, :string, default: nil
  attr :class, :string, default: nil
  slot :inner_block, required: true

  defp nav_link_href(%{href: href} = assigns) when is_binary(href) do
    if external_href?(href) do
      ~H"""
      <a href={@href} target="_blank" rel="noopener" class={@class}>{render_slot(@inner_block)}</a>
      """
    else
      ~H"""
      <.link navigate={@href} class={@class}>{render_slot(@inner_block)}</.link>
      """
    end
  end

  defp nav_link_href(assigns) do
    ~H"""
    <span class={@class}>{render_slot(@inner_block)}</span>
    """
  end

  defp external_href?(href), do: String.starts_with?(href, "http://") or String.starts_with?(href, "https://")

  attr :label, :string, required: true
  slot :inner_block, required: true

  defp nav_dropdown(assigns) do
    ~H"""
    <div class="group relative shrink-0">
      <button
        type="button"
        class="flex items-center gap-1 whitespace-nowrap font-head text-[15px] font-medium uppercase tracking-wide text-white transition group-hover:text-crimson"
      >
        {@label}
        <svg
          class="h-4 w-4"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          aria-hidden="true"
        >
          <polyline points="6 9 12 15 18 9" />
        </svg>
      </button>
      <div class="absolute left-0 top-full z-[60] hidden pt-3 group-hover:block group-focus-within:block">
        <div class="grid min-w-[220px] grid-cols-1 gap-y-2 rounded-md bg-white p-6 shadow-2xl">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  attr :url, :string, required: true
  attr :title, :string, required: true
  attr :label, :string, default: "Share this story"
  attr :id, :string, default: "copy-link-button"

  @doc """
  Social share links plus a copy-to-clipboard button for any shareable page.
  """
  def share_bar(assigns) do
    %{url: url, title: title} = assigns
    url = share_value(url, Seo.site_url())
    title = share_value(title, Seo.site_name())
    encoded_url = URI.encode_www_form(url)
    encoded_title = URI.encode_www_form(title)

    assigns =
      assign(assigns,
        url: url,
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
        {@label}
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
          id={@id}
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

  defp share_value(value, fallback) when is_binary(value) do
    if String.trim(value) == "", do: fallback, else: value
  end

  defp share_value(_, fallback), do: fallback

  attr :id, :string, default: nil
  attr :base_path, :string, default: ""

  def site_footer(assigns) do
    assigns =
      assign(assigns, :social_links, @social_links)

    ~H"""
    <section class="relative overflow-hidden bg-gradient-to-r from-crimson via-crimson to-rose-600">
      <div class="mx-auto flex max-w-container flex-col items-center gap-6 px-4 py-12 text-center lg:px-6 lg:py-14">
        <div>
          <h2 class="font-head text-3xl font-bold uppercase tracking-[0.06em] text-white sm:text-4xl md:text-5xl">
            Join the Conversation
          </h2>
        </div>

        <div class="flex flex-wrap items-center justify-center gap-4 sm:gap-5">
          <.social_link
            :for={link <- @social_links}
            link={link}
            class="social-dance flex h-14 w-14 items-center justify-center rounded-full bg-white text-crimson shadow-[0_8px_24px_rgba(0,0,0,0.25)] transition duration-300 ease-out hover:-translate-y-1.5 hover:scale-110 hover:bg-blueink hover:text-white sm:h-16 sm:w-16 [&_svg]:h-7 [&_svg]:w-7"
          />
        </div>
      </div>
    </section>

    <footer id={@id} class="border-t border-white/10 bg-blueink text-white">
      <div class="mx-auto max-w-container px-4 py-8 lg:px-6 lg:py-10">
        <div class="flex flex-col items-center gap-8 border-b border-white/10 pb-6 text-center lg:flex-row lg:items-center lg:justify-between lg:text-left">
          <a href={section_href(@base_path, "top")} class="shrink-0">
            <img src="/images/logo.png" alt="Maraga '27" class="h-14 w-auto" />
          </a>

          <div>
            <p class="font-head text-[11px] uppercase tracking-[0.24em] text-crimson">
              Campaign HQ
            </p>
            <p class="mt-3 text-sm leading-6 text-white/78">
              Off Vihiga Rd, Kileleshwa, Nairobi
            </p>
            <p class="mt-2">
              <a
                href="tel:+254746900027"
                class="text-sm text-white/78 transition hover:text-crimson"
              >
                +254 746 900 027
              </a>
            </p>
            <p class="mt-2">
              <a
                href="mailto:infodesk@davidmaraga.com"
                class="text-sm text-white/78 transition hover:text-crimson"
              >
                infodesk@davidmaraga.com
              </a>
            </p>
          </div>
        </div>

        <nav class="mt-6 flex flex-nowrap items-center justify-center gap-x-5 overflow-x-auto whitespace-nowrap font-head text-xs uppercase tracking-[0.18em] text-white/78">
          <a href={section_href(@base_path, "top")} class="transition hover:text-crimson">Home</a>
          <a href={section_href(@base_path, "mission")} class="transition hover:text-crimson">
            About
          </a>
          <a href="/news" class="transition hover:text-crimson">News</a>
          <a href={section_href(@base_path, "agenda")} class="transition hover:text-crimson">
            Agenda
          </a>
          <a href="/media/photos" class="transition hover:text-crimson">Photos</a>
          <a href="/press-releases" class="transition hover:text-crimson">Press</a>
          <a
            href="https://donations.davidmaraga.com/"
            target="_blank"
            rel="noopener"
            class="transition hover:text-crimson"
          >
            Donate
          </a>
        </nav>
      </div>
    </footer>
    """
  end

  defp section_href("", section), do: "##{section}"
  defp section_href(base_path, section), do: "#{base_path}##{section}"

  defp news_category_href(category),
    do: "/news?category=" <> URI.encode_www_form(category)

  defp open_search_modal(js \\ %JS{}) do
    js
    |> show_modal("site-search-modal")
    |> JS.dispatch("site-search:open", to: "#site-search-panel")
  end

  defp build_search_items(base_path, news_categories) do
    static_search_items(base_path, news_categories) ++
      post_search_items() ++ event_search_items() ++ media_search_items()
  end

  defp static_search_items(base_path, news_categories) do
    [
      %{
        group: "Section",
        title: "Top of Homepage",
        href: section_href(base_path, "top"),
        description: "Return to the top banner and hero.",
        external?: false,
        search_text: "top homepage hero home"
      },
      %{
        group: "Section",
        title: "Mission",
        href: section_href(base_path, "mission"),
        description: "Jump to the bio and support the campaign section.",
        external?: false,
        search_text: "mission about values bio donate support"
      },
      %{
        group: "Section",
        title: "News Section",
        href: section_href(base_path, "news"),
        description: "Go to the homepage news highlights.",
        external?: false,
        search_text: "news latest updates headlines"
      },
      %{
        group: "Section",
        title: "Newsletter Section",
        href: section_href(base_path, "newsletter"),
        description: "Open the newsletter and subscriber area.",
        external?: false,
        search_text: "newsletter subscribe email"
      },
      %{
        group: "Section",
        title: "Events Section",
        href: section_href(base_path, "events"),
        description: "Jump to featured campaign events.",
        external?: false,
        search_text: "events rallies calendar"
      },
      %{
        group: "Section",
        title: "Agenda Section",
        href: section_href(base_path, "agenda"),
        description: "Go to the agenda and video section.",
        external?: false,
        search_text: "agenda priorities videos"
      },
      %{
        group: "Section",
        title: "Gallery Section",
        href: section_href(base_path, "gallery"),
        description: "Open the homepage photo gallery.",
        external?: false,
        search_text: "gallery photos media"
      },
      %{
        group: "Page",
        title: "David Maraga",
        href: "/david-maraga",
        description: "Biography and background.",
        external?: false,
        search_text: "david maraga biography profile"
      },
      %{
        group: "Page",
        title: "UGM Party",
        href: "/ugm-party",
        description: "Read about the party.",
        external?: false,
        search_text: "ugm party about"
      },
      %{
        group: "Page",
        title: "Campaign Pillars",
        href: "/campaign-pillars",
        description: "Policy themes and agenda.",
        external?: false,
        search_text: "campaign pillars manifesto agenda policy"
      },
      %{
        group: "Page",
        title: "Latest News",
        href: "/news",
        description: "Browse all published news.",
        external?: false,
        search_text: "news latest updates headlines"
      },
      %{
        group: "Page",
        title: "Blogs",
        href: "/blog",
        description: "Opinion and long-form writing.",
        external?: false,
        search_text: "blog blogs opinion analysis"
      },
      %{
        group: "Page",
        title: "Newsletters",
        href: "/newsletters",
        description: "Campaign newsletters and bulletins.",
        external?: false,
        search_text: "newsletters newsletter bulletins"
      },
      %{
        group: "Page",
        title: "Press Releases",
        href: "/press-releases",
        description: "Official statements and releases.",
        external?: false,
        search_text: "press releases statements media"
      },
      %{
        group: "Page",
        title: "Media Invitations",
        href: "/media-invitations",
        description: "Invitations and press notices.",
        external?: false,
        search_text: "media invitations press notices"
      },
      %{
        group: "Page",
        title: "Events Calendar",
        href: "/events",
        description: "Upcoming rallies, town halls, and appearances.",
        external?: false,
        search_text: "events calendar rallies town halls"
      },
      %{
        group: "Page",
        title: "Photo Gallery",
        href: "/media/photos",
        description: "Campaign photos and highlights.",
        external?: false,
        search_text: "photos gallery media images"
      },
      %{
        group: "Page",
        title: "Video Gallery",
        href: "/media/videos",
        description: "Campaign videos and clips.",
        external?: false,
        search_text: "videos media clips interviews"
      },
      %{
        group: "Page",
        title: "Shop",
        href: "https://davidmaraga.shop",
        description: "Official merchandise store.",
        external?: true,
        search_text: "shop merchandise store"
      }
    ] ++
      Enum.map(news_categories, fn category ->
        %{
          group: "Category",
          title: category,
          href: news_category_href(category),
          description: "Open news filtered to this category.",
          external?: false,
          search_text: "#{category} news category"
        }
      end)
  end

  defp post_search_items do
    # Every published article is indexed (not just the newest handful) so the
    # header search can match on any keyword in a story's body.
    Content.list_published_posts()
    |> Enum.map(fn post ->
      %{
        group: post.category,
        title: post.title,
        href: "/blog/#{post.slug}",
        description: Post.summary(post, 120),
        external?: false,
        search_text:
          search_blob([
            post.title,
            post.category,
            String.replace(post.slug || "", "-", " "),
            post.seo_description,
            post.preview_text,
            post.newsletter_volume,
            post.body
          ])
      }
    end)
  end

  defp media_search_items do
    Content.list_published_media_items()
    |> Enum.map(fn item ->
      %{
        group: if(item.media_type == "video", do: "Video", else: "Photo"),
        title: item.title,
        href: if(item.media_type == "video", do: "/media/videos", else: "/media/photos"),
        description: item.description,
        external?: false,
        search_text:
          search_blob([
            item.title,
            item.description,
            item.category,
            item.media_type,
            "media gallery"
          ])
      }
    end)
  end

  # Flattens a list of fields into a single plain-text haystack: HTML is
  # stripped so rich-text bodies are searchable, and whitespace collapsed.
  defp search_blob(fields) do
    fields
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> String.replace(~r/<[^>]*>/u, " ")
    |> String.replace(~r/&[a-z]+;|&#\d+;/ui, " ")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end

  defp event_search_items do
    Content.list_published_events()
    |> Enum.map(fn event ->
      %{
        group: "Event",
        title: event.title,
        href: "/events/#{event.id}",
        description:
          [format_event_date(event.starts_at), event.location]
          |> Enum.reject(&blank?/1)
          |> Enum.join(" · "),
        external?: false,
        search_text:
          search_blob([event.title, event.location, event.description, "event calendar"])
      }
    end)
  end

  defp format_event_date(%DateTime{} = starts_at),
    do: Calendar.strftime(starts_at, "%b %-d, %Y")

  defp format_event_date(_), do: nil

  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(nil), do: true
  defp blank?(_), do: false

  attr :link, :map, required: true
  attr :class, :string, default: ""

  defp social_link(assigns) do
    ~H"""
    <a href={@link.href} target="_blank" rel="noopener" aria-label={@link.label} class={@class}>
      <.social_icon name={@link.name} />
    </a>
    """
  end

  attr :name, :string, required: true

  defp social_icon(%{name: "facebook"} = assigns) do
    ~H"""
    <svg class="h-[18px] w-[18px]" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M22 12a10 10 0 1 0-11.56 9.88v-6.99H7.9V12h2.54V9.8c0-2.5 1.49-3.89 3.78-3.89 1.09 0 2.24.2 2.24.2v2.46h-1.26c-1.24 0-1.63.77-1.63 1.56V12h2.78l-.44 2.89h-2.34v6.99A10 10 0 0 0 22 12z" />
    </svg>
    """
  end

  defp social_icon(%{name: "x"} = assigns) do
    ~H"""
    <svg class="h-[16px] w-[16px]" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24h-6.66l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
    </svg>
    """
  end

  defp social_icon(%{name: "instagram"} = assigns) do
    ~H"""
    <svg
      class="h-[18px] w-[18px]"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      <rect x="2" y="2" width="20" height="20" rx="5" ry="5" />
      <path d="M16 11.37a4 4 0 1 1-7.91 1.17 4 4 0 0 1 7.91-1.17z" />
      <line x1="17.5" y1="6.5" x2="17.51" y2="6.5" />
    </svg>
    """
  end

  defp social_icon(%{name: "youtube"} = assigns) do
    ~H"""
    <svg class="h-[18px] w-[18px]" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M23.5 6.2a3 3 0 0 0-2.1-2.12C19.53 3.5 12 3.5 12 3.5s-7.53 0-9.4.58A3 3 0 0 0 .5 6.2 31.4 31.4 0 0 0 0 12a31.4 31.4 0 0 0 .5 5.8 3 3 0 0 0 2.1 2.12c1.87.58 9.4.58 9.4.58s7.53 0 9.4-.58a3 3 0 0 0 2.1-2.12A31.4 31.4 0 0 0 24 12a31.4 31.4 0 0 0-.5-5.8ZM9.6 15.94V8.06L16.4 12 9.6 15.94Z" />
    </svg>
    """
  end

  defp social_icon(%{name: "tiktok"} = assigns) do
    ~H"""
    <svg class="h-[18px] w-[18px]" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M16.6 5.82a4.28 4.28 0 0 1-1.05-2.82h-3.1v12.42a2.6 2.6 0 1 1-1.84-2.49V9.74a5.7 5.7 0 1 0 4.94 5.65V9.01a7.32 7.32 0 0 0 4.28 1.37V7.28a4.28 4.28 0 0 1-3.18-1.46z" />
    </svg>
    """
  end
end
