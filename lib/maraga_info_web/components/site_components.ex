defmodule MaragaInfoWeb.SiteComponents do
  use Phoenix.Component

  @social_links [
    %{name: "x", href: "https://x.com/dkmaraga", label: "X"},
    %{name: "instagram", href: "https://www.instagram.com/maraga2027", label: "Instagram"},
    %{name: "youtube", href: "https://www.youtube.com/@dkmaraga", label: "YouTube"}
  ]

  attr :id, :string, default: nil
  attr :base_path, :string, default: ""

  def site_footer(assigns) do
    assigns =
      assign(assigns, :social_links, @social_links)

    ~H"""
    <footer id={@id} class="border-t border-white/10 bg-blueink text-white">
      <div class="mx-auto max-w-container px-4 py-14 lg:px-6 lg:py-16">
        <div class="grid gap-10 lg:grid-cols-[1.3fr_0.9fr] lg:items-end">
          <div>
            <div class="flex items-center gap-4">
              <img src="/images/logo.png" alt="David Maraga Info logo" class="h-12 w-auto rounded-sm" />
              <div>
                <p class="font-head text-[11px] uppercase tracking-[0.32em] text-crimson">
                  Kenya 2027
                </p>
                <h2 class="mt-2 font-head text-2xl uppercase leading-none text-white sm:text-3xl">
                  David Maraga Info
                </h2>
              </div>
            </div>

            <p class="mt-5 max-w-xl text-base leading-7 text-white/72">
              Independent coverage, campaign updates and public record context in one place.
            </p>
          </div>

          <nav class="flex flex-wrap gap-x-6 gap-y-3 font-head text-xs uppercase tracking-[0.2em] text-white/78 lg:justify-end">
            <a href={section_href(@base_path, "top")} class="transition hover:text-crimson">Home</a>
            <a href={section_href(@base_path, "mission")} class="transition hover:text-crimson">
              About
            </a>
            <a href={section_href(@base_path, "news")} class="transition hover:text-crimson">
              News
            </a>
            <a href={section_href(@base_path, "agenda")} class="transition hover:text-crimson">
              Agenda
            </a>
            <a href={section_href(@base_path, "gallery")} class="transition hover:text-crimson">
              Gallery
            </a>
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

        <div class="mt-10 flex flex-col gap-5 border-t border-white/15 pt-6 lg:flex-row lg:items-center lg:justify-between">
          <div class="flex items-center gap-3">
            <.social_link
              :for={link <- @social_links}
              link={link}
              class="flex h-10 w-10 items-center justify-center rounded-full border border-white/20 text-white/80 transition hover:border-crimson hover:text-white"
            />
          </div>

          <p>
            © {Date.utc_today().year} David Maraga Info. Integrity, justice and service for Kenya.
          </p>

          <div class="flex flex-wrap items-center gap-4 font-head text-[11px] uppercase tracking-[0.2em] text-white/68">
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
end
