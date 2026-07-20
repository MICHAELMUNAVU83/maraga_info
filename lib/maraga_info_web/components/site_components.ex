defmodule MaragaInfoWeb.SiteComponents do
  use Phoenix.Component

  alias MaragaInfo.Content
  alias MaragaInfo.Content.Post
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
        <nav class="hidden items-center gap-6 lg:flex">
          <div class="mr-2 flex items-center gap-3">
            <.social_link
              :for={link <- @social_links}
              link={link}
              class="text-white transition [filter:drop-shadow(0_0_5px_rgba(255,255,255,0.7))] hover:text-crimson hover:[filter:drop-shadow(0_0_9px_rgba(225,29,72,0.9))]"
            />
          </div>
          <a
            href={section_href(@base_path, "top")}
            class="font-head text-[15px] font-medium uppercase tracking-wide text-crimson"
          >
            Home
          </a>

          <.nav_dropdown label="About Us">
            <.link navigate="/david-maraga" class="text-[15px] text-ink transition hover:text-crimson">
              David Maraga
            </.link>
            <.link navigate="/ugm-party" class="text-[15px] text-ink transition hover:text-crimson">
              UGM Party
            </.link>
          </.nav_dropdown>

          <.nav_dropdown label="Our Agenda">
            <.link
              navigate="/campaign-pillars"
              class="text-[15px] text-ink transition hover:text-crimson"
            >
              Campaign Pillars
            </.link>
            <a href="#" class="text-[15px] text-ink transition hover:text-crimson">
              Manifesto
            </a>
          </.nav_dropdown>
        </nav>

        <a href={section_href(@base_path, "top")} class="flex shrink-0 items-center gap-2 lg:hidden">
          <img
            src="/images/PHOTO-2026-06-14-22-19-17.jpg"
            alt="David Maraga logo"
            class="h-12 w-auto shrink-0"
          />
        </a>

        <a
          href={section_href(@base_path, "top")}
          class="absolute left-1/2 top-0 z-50 hidden -translate-x-1/2 flex-col items-center rounded-b-md bg-crimson px-8 pb-4 pt-2.5 shadow-lg lg:flex"
        >
          <img
            src="/images/logo.png"
            alt="Politician 128 logo"
            class="hidden h-12 w-auto shrink-0 lg:block"
          />
        </a>

        <div class="flex items-center gap-6">
          <nav class="hidden items-center gap-6 lg:flex">
            <.nav_dropdown label="Resources">
              <.link
                navigate="/newsletters"
                class="text-[15px] text-ink transition hover:text-crimson"
              >
                Newsletters
              </.link>
              <.nav_submenu label="News" navigate="/news">
                <.link
                  :for={category <- @news_categories}
                  navigate={news_category_href(category)}
                  class="text-[14px] text-grayink transition hover:text-crimson"
                >
                  {category}
                </.link>
              </.nav_submenu>
              <.link navigate="/blog" class="text-[15px] text-ink transition hover:text-crimson">
                Blogs
              </.link>
              <.nav_submenu label="Media">
                <.link
                  navigate="/media/photos"
                  class="text-[14px] text-grayink transition hover:text-crimson"
                >
                  Photos
                </.link>
                <.link
                  navigate="/media/videos"
                  class="text-[14px] text-grayink transition hover:text-crimson"
                >
                  Videos
                </.link>
              </.nav_submenu>
            </.nav_dropdown>
            <.nav_dropdown label="Press">
              <.link
                navigate="/press-releases"
                class="text-[15px] text-ink transition hover:text-crimson"
              >
                Press Releases
              </.link>
              <a href="/media-invitations" class="text-[15px] text-ink transition hover:text-crimson">
                Media Invitations
              </a>
            </.nav_dropdown>
            <.link
              navigate="/events"
              class="font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
            >
              Events
            </.link>
            <a
              href="https://davidmaraga.shop"
              target="_blank"
              rel="noopener"
              class="font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
            >
              Shop
            </a>
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

        <p class="pt-3 font-head text-[12px] font-semibold uppercase tracking-[0.2em] text-white/60">
          About Us
        </p>
        <.link
          navigate="/david-maraga"
          class="py-1 pl-3 text-[14px] text-white/85 transition hover:text-crimson"
        >
          David Maraga
        </.link>
        <.link
          navigate="/ugm-party"
          class="py-1 pl-3 text-[14px] text-white/85 transition hover:text-crimson"
        >
          UGM Party
        </.link>

        <p class="pt-3 font-head text-[12px] font-semibold uppercase tracking-[0.2em] text-white/60">
          Our Agenda
        </p>
        <.link
          navigate="/campaign-pillars"
          class="py-1 pl-3 text-[14px] text-white/85 transition hover:text-crimson"
        >
          Campaign Pillars
        </.link>
        <a href="#" class="py-1 pl-3 text-[14px] text-white/85 transition hover:text-crimson">
          Manifesto
        </a>

        <p class="pt-3 font-head text-[12px] font-semibold uppercase tracking-[0.2em] text-white/60">
          Resources
        </p>
        <.link
          navigate="/newsletters"
          class="py-1 pl-3 text-[14px] text-white/85 transition hover:text-crimson"
        >
          Newsletters
        </.link>
        <details class="group pl-3">
          <summary class="flex w-full cursor-pointer list-none items-center gap-2 py-1 text-[14px] text-white/85 transition hover:text-crimson">
            News
            <svg
              class="h-4 w-4 transition group-open:rotate-180"
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
          </summary>
          <div class="grid gap-1 pb-1 pl-3 pt-1">
            <.link
              navigate="/news"
              class="py-1 text-[13px] text-white/75 transition hover:text-crimson"
            >
              All News
            </.link>
            <p class="pt-1 font-head text-[12px] font-semibold uppercase tracking-[0.16em] text-white/55">
              Categories
            </p>
            <.link
              :for={category <- @news_categories}
              navigate={news_category_href(category)}
              class="py-1 text-[13px] text-white/65 transition hover:text-crimson"
            >
              {category}
            </.link>
          </div>
        </details>
        <.link
          navigate="/blog"
          class="py-1 pl-3 text-[14px] text-white/85 transition hover:text-crimson"
        >
          Blogs
        </.link>
        <details class="group pl-3">
          <summary class="flex w-full cursor-pointer list-none items-center gap-2 py-1 text-[14px] text-white/85 transition hover:text-crimson">
            Media
            <svg
              class="h-4 w-4 transition group-open:rotate-180"
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
          </summary>
          <div class="grid gap-1 pb-1 pl-3 pt-1">
            <.link
              navigate="/media/photos"
              class="py-1 text-[13px] text-white/75 transition hover:text-crimson"
            >
              Photos
            </.link>
            <.link
              navigate="/media/videos"
              class="py-1 text-[13px] text-white/75 transition hover:text-crimson"
            >
              Videos
            </.link>
          </div>
        </details>

        <p class="pt-3 font-head text-[12px] font-semibold uppercase tracking-[0.2em] text-white/60">
          Press
        </p>
        <.link
          navigate="/press-releases"
          class="py-1 pl-3 text-[14px] text-white/85 transition hover:text-crimson"
        >
          Press Releases
        </.link>
        <a
          href="/media-invitations"
          class="py-1 pl-3 text-[14px] text-white/85 transition hover:text-crimson"
        >
          Media Invitations
        </a>

        <.link
          navigate="/events"
          class="py-1 pt-3 font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
        >
          Events
        </.link>

        <a
          href="https://davidmaraga.shop"
          target="_blank"
          rel="noopener"
          class="py-1 font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
        >
          Shop
        </a>
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

  attr :label, :string, required: true
  slot :inner_block, required: true

  defp nav_dropdown(assigns) do
    ~H"""
    <div class="group relative">
      <button
        type="button"
        class="flex items-center gap-1 font-head text-[15px] font-medium uppercase tracking-wide text-white transition group-hover:text-crimson"
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
      <div class="absolute left-0 top-full z-50 hidden pt-3 group-hover:block group-focus-within:block">
        <div class="grid min-w-[220px] grid-cols-1 gap-y-2 rounded-md bg-white p-6 shadow-2xl">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :navigate, :string, default: nil
  slot :inner_block, required: true

  defp nav_submenu(assigns) do
    ~H"""
    <div class="relative">
      <div class="group/nav-sub rounded-md transition hover:bg-slate-50 focus-within:bg-slate-50">
        <div class="flex items-center justify-between gap-3 rounded-md py-1.5">
          <%= if @navigate do %>
            <.link navigate={@navigate} class="text-[15px] text-ink transition hover:text-crimson">
              {@label}
            </.link>
          <% else %>
            <span class="text-[15px] text-ink">{@label}</span>
          <% end %>
          <svg
            class="h-4 w-4 text-grayink transition group-hover/nav-sub:text-crimson group-focus-within/nav-sub:text-crimson"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <polyline points="9 6 15 12 9 18" />
          </svg>
        </div>
        <div class="absolute left-full top-0 z-[60] ml-2 hidden min-w-[190px] grid-cols-1 gap-y-2 rounded-md bg-white p-4 shadow-2xl group-hover/nav-sub:grid group-focus-within/nav-sub:grid">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, default: nil
  attr :base_path, :string, default: ""

  def site_footer(assigns) do
    assigns =
      assign(assigns, :social_links, @social_links)

    ~H"""
    <section class="relative overflow-hidden bg-gradient-to-r from-crimson via-crimson to-rose-600">
      <div class="mx-auto flex max-w-container flex-col items-center gap-6 px-4 py-12 text-center lg:px-6 lg:py-14">
        <div>
          <p class="font-serifi text-xl italic text-white/90 sm:text-2xl">Let's Connect</p>
          <h2 class="mt-2 font-head text-3xl font-bold uppercase tracking-[0.06em] text-white sm:text-4xl md:text-5xl">
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
        <div class="grid gap-8 border-b border-white/10 pb-6 text-center lg:grid-cols-[1fr_auto_1fr] lg:items-center lg:text-left">
          <div class="flex flex-col items-center gap-4 lg:items-start">
            <div class="flex items-center gap-3">
              <img
                src="/images/PHOTO-2026-06-14-22-19-17.jpg"
                alt="David Maraga Info logo"
                class="h-10 w-auto"
              />
              <div>
                <p class="font-head text-[10px] uppercase tracking-[0.32em] text-crimson">
                  Kenya 2027
                </p>
                <h2 class="font-head text-xl uppercase leading-none text-white sm:text-2xl">
                  David Maraga Info
                </h2>
              </div>
            </div>

            <p class="mt-3 max-w-xl text-sm leading-6 text-white/72">
              Independent coverage, campaign updates and public record context in one place.
            </p>
          </div>

          <div class="mx-auto max-w-sm">
            <p class="font-head text-[11px] uppercase tracking-[0.24em] text-crimson">
              Campaign HQ
            </p>
            <p class="mt-3 text-sm leading-6 text-white/78">
              Off Vihiga Rd, Kileleshwa, Nairobi
            </p>
            <a
              href="tel:+254746900027"
              class="mt-1 inline-flex text-sm text-white/78 transition hover:text-crimson"
            >
              +254 746 900 027
            </a>
            <a
              href="mailto:infodesk@davidmaraga.com"
              class="mt-1 inline-flex text-sm text-white/78 transition hover:text-crimson"
            >
              infodesk@davidmaraga.com
            </a>
          </div>

          <div class="flex flex-col gap-4 lg:items-end">
            <nav class="flex flex-wrap justify-center gap-x-5 gap-y-2 font-head text-xs uppercase tracking-[0.18em] text-white/78 lg:justify-end">
              <a href={section_href(@base_path, "top")} class="transition hover:text-crimson">Home</a>
              <a href={section_href(@base_path, "mission")} class="transition hover:text-crimson">
                About
              </a>
              <a href="/news" class="transition hover:text-crimson">News</a>
              <a href={section_href(@base_path, "agenda")} class="transition hover:text-crimson">
                Agenda
              </a>
              <a href="/press-releases" class="transition hover:text-crimson">Press</a>
              <a href="/media/photos" class="transition hover:text-crimson">Photos</a>
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
        </div>

        <div class="mt-4 flex flex-col gap-2 pt-4 text-center text-xs text-white/68 sm:flex-row sm:items-center sm:justify-between sm:text-left">
          <p>
            © {Date.utc_today().year} David Maraga Info. Integrity, justice and service for Kenya.
          </p>

          <div class="flex flex-wrap items-center justify-center gap-4 font-head uppercase tracking-[0.18em] sm:justify-end">
            <a href="https://davidmaraga.info/" class="transition hover:text-crimson">
              davidmaraga.info
            </a>
          </div>
        </div>
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
      post_search_items() ++ event_search_items()
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
        description: "Jump to the mission and about section.",
        external?: false,
        search_text: "mission about values"
      },
      %{
        group: "Section",
        title: "Documentary",
        href: section_href(base_path, "documentary"),
        description: "Open the documentary feature block.",
        external?: false,
        search_text: "documentary feature story"
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
    Content.list_published_posts(limit: 12)
    |> Enum.map(fn post ->
      %{
        group: post.category,
        title: post.title,
        href: "/blog/#{post.slug}",
        description: Post.summary(post, 120),
        external?: false,
        search_text:
          Enum.join(
            [
              post.title,
              post.category,
              post.slug,
              post.seo_description,
              Post.summary(post, 160)
            ],
            " "
          )
      }
    end)
  end

  defp event_search_items do
    Content.list_upcoming_events(limit: 8)
    |> Enum.map(fn event ->
      %{
        group: "Event",
        title: event.title,
        href: "/events",
        description:
          [format_event_date(event.starts_at), event.location]
          |> Enum.reject(&blank?/1)
          |> Enum.join(" · "),
        external?: false,
        search_text:
          Enum.join([event.title, event.location, event.description, "event calendar"], " ")
      }
    end)
  end

  defp format_event_date(%DateTime{} = starts_at),
    do: Calendar.strftime(starts_at, "%b %-d, %Y")

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
