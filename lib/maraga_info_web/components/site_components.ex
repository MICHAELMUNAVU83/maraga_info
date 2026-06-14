defmodule MaragaInfoWeb.SiteComponents do
  use Phoenix.Component

  @social_links [
    %{name: "x", href: "https://x.com/dkmaraga", label: "X"},
    %{name: "instagram", href: "https://www.instagram.com/maraga2027", label: "Instagram"},
    %{name: "youtube", href: "https://www.youtube.com/@dkmaraga", label: "YouTube"},
    %{name: "facebook", href: "https://www.facebook.com/Maraga2027", label: "Facebook"},
    %{name: "tiktok", href: "https://www.tiktok.com/@maraga2027", label: "TikTok"}
  ]

  attr :base_path, :string, default: ""

  def site_header(assigns) do
    assigns = assign(assigns, :social_links, @social_links)

    ~H"""
    <header class="relative z-30 w-full bg-blueink">
      <input id="nav-toggle" type="checkbox" class="peer hidden" />

      <div class="relative mx-auto flex w-full max-w-container items-center justify-between gap-4 px-4 py-3 lg:px-6">
        <nav class="hidden items-center gap-6 lg:flex">
          <div class="mr-2 flex items-center gap-3">
            <.social_link
              :for={link <- @social_links}
              link={link}
              class="text-white transition hover:text-crimson"
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
          <svg class="h-8 w-8" viewBox="0 0 32 32" aria-hidden="true">
            <rect width="32" height="32" rx="6" fill="#fff" />
            <path
              d="M11 24V8h6.2c3.1 0 5 1.9 5 4.9s-1.9 5-5 5H15V24h-4zm4-9.4h1.8c1 0 1.6-.6 1.6-1.6s-.6-1.6-1.6-1.6H15v3.2z"
              fill="#026631"
            />
          </svg>
          <span class="font-head text-lg font-bold tracking-wide text-white">
            <img
              src="/images/logo.png"
              alt="Politician 128 logo"
              class="hidden h-24 w-auto shrink-0 lg:block"
            />
          </span>
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
              <.link navigate="/news" class="text-[15px] text-ink transition hover:text-crimson">
                News
              </.link>
              <.link
                navigate="/press-releases"
                class="text-[15px] text-ink transition hover:text-crimson"
              >
                Press Releases
              </.link>
              <a
                href={section_href(@base_path, "news")}
                class="text-[15px] text-ink transition hover:text-crimson"
              >
                Blogs
              </a>
              <a
                href={section_href(@base_path, "events")}
                class="text-[15px] text-ink transition hover:text-crimson"
              >
                Events
              </a>
              <.link navigate="/media" class="text-[15px] text-ink transition hover:text-crimson">
                Media
              </.link>
            </.nav_dropdown>
            <a
              href="#"
              class="font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
            >
              Press Releases
            </a>
            <a
              href="https://davidmaraga.com/shop"
              target="_blank"
              rel="noopener"
              class="font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
            >
              Shop
            </a>
          </nav>

          <.link
            navigate="/admin"
            aria-label="Admin"
            title="Admin"
            class="flex h-9 w-9 items-center justify-center rounded-full border border-white/30 text-white transition hover:border-crimson hover:text-crimson"
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
        <.link
          navigate="/news"
          class="py-1 pl-3 text-[14px] text-white/85 transition hover:text-crimson"
        >
          News
        </.link>
        <.link
          navigate="/press-releases"
          class="py-1 pl-3 text-[14px] text-white/85 transition hover:text-crimson"
        >
          Press Releases
        </.link>
        <a
          href={section_href(@base_path, "news")}
          class="py-1 pl-3 text-[14px] text-white/85 transition hover:text-crimson"
        >
          Blogs
        </a>
        <.link
          navigate="/media"
          class="py-1 pl-3 text-[14px] text-white/85 transition hover:text-crimson"
        >
          Media
        </.link>

        <a
          href="#"
          class="py-1 pt-3 font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
        >
          Press Releases
        </a>
        <a
          href="#"
          class="py-1 font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
        >
          Shop
        </a>
        <.link
          navigate="/admin"
          class="py-1 font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
        >
          Admin
        </.link>
      </nav>
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
      <div class="absolute left-0 top-full z-50 hidden min-w-[200px] grid-cols-1 gap-y-2 rounded-md bg-white p-6 shadow-2xl group-hover:grid group-focus-within:grid">
        {render_slot(@inner_block)}
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
    <footer id={@id} class="border-t border-white/10 bg-blueink text-white">
      <div class="mx-auto max-w-container px-4 py-8 lg:px-6 lg:py-10">
        <div class="grid gap-6 lg:grid-cols-[1.4fr_1fr] lg:items-start">
          <div>
            <div class="flex items-center gap-3">
              <img
                src="/images/logo.png"
                alt="David Maraga Info logo"
                class="h-10 bg-white w-auto rounded-sm"
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

            <p class="mt-4 text-sm text-white/72">
              <span class="font-head text-[11px] uppercase tracking-[0.2em] text-crimson">
                Campaign HQ:
              </span>
              82 Westlands Rd, Nairobi, Kenya ·
              <a href="tel:+254746900027" class="transition hover:text-crimson">+254 746 900 027</a>
            </p>
          </div>

          <div class="flex flex-col gap-4 lg:items-end">
            <nav class="flex flex-wrap gap-x-5 gap-y-2 font-head text-xs uppercase tracking-[0.2em] text-white/78 lg:justify-end">
              <a href={section_href(@base_path, "top")} class="transition hover:text-crimson">Home</a>
              <a href={section_href(@base_path, "mission")} class="transition hover:text-crimson">
                About
              </a>
              <a href="/news" class="transition hover:text-crimson">News</a>
              <a href={section_href(@base_path, "agenda")} class="transition hover:text-crimson">
                Agenda
              </a>
              <a href="/media" class="transition hover:text-crimson">Media</a>
              <a
                href="https://donations.davidmaraga.com/"
                target="_blank"
                rel="noopener"
                class="transition hover:text-crimson"
              >
                Donate
              </a>
            </nav>

            <div class="flex items-center gap-2.5 lg:justify-end">
              <.social_link
                :for={link <- @social_links}
                link={link}
                class="social-dance flex h-9 w-9 items-center justify-center rounded-full border border-white/20 text-white/80 transition duration-300 ease-out hover:-translate-y-1 hover:scale-110 hover:border-crimson hover:bg-crimson hover:text-white hover:shadow-lg hover:shadow-crimson/30"
              />
            </div>
          </div>
        </div>

        <div class="mt-6 flex flex-col gap-2 border-t border-white/15 pt-4 text-xs text-white/68 sm:flex-row sm:items-center sm:justify-between">
          <p>
            © {Date.utc_today().year} David Maraga Info. Integrity, justice and service for Kenya.
          </p>

          <div class="flex flex-wrap items-center gap-4 font-head uppercase tracking-[0.2em]">
            <a href="https://davidmaraga.info/" class="transition hover:text-crimson">
              davidmaraga.info
            </a>
            <a href={section_href(@base_path, "volunteer")} class="transition hover:text-crimson">
              Volunteer
            </a>
          </div>
        </div>
      </div>
    </footer>
    """
  end

  defp section_href("", section), do: "##{section}"
  defp section_href(base_path, section), do: "#{base_path}##{section}"

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
