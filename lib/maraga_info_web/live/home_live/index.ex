defmodule MaragaInfoWeb.HomeLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfo.Content.Post
  alias MaragaInfo.Volunteers
  alias MaragaInfo.Volunteers.WelcomeNotifier
  alias MaragaInfoWeb.Seo

  @social_links [
    %{name: "x", href: "https://x.com/dkmaraga", label: "X"},
    %{name: "instagram", href: "https://www.instagram.com/maraga2027", label: "Instagram"},
    %{name: "youtube", href: "https://www.youtube.com/@dkmaraga", label: "YouTube"}
  ]

  @fallback_videos [
    %{
      title: "Maraga Arrested at Nairobi Protest",
      thumb: "/images/maxresdefault.jpg",
      href: "https://www.youtube.com/watch?v=o0KmjcGd6jw"
    },
    %{
      title: "Ukombozi Campaign Launch — Turkana",
      thumb: "/images/gallery/1.jpg",
      href: "https://www.youtube.com/@dkmaraga"
    },
    %{
      title: "On the Campaign Trail",
      thumb: "/images/gallery/2.jpg",
      href: "https://www.youtube.com/@dkmaraga"
    },
    %{
      title: "Justice for Every County",
      thumb: "/images/gallery/3.jpg",
      href: "https://www.youtube.com/@dkmaraga"
    },
    %{
      title: "Meet David Maraga",
      thumb: "/images/gallery/4.jpg",
      href: "https://www.youtube.com/@dkmaraga"
    },
    %{
      title: "Rallying for 2027",
      thumb: "/images/gallery/5.jpg",
      href: "https://www.youtube.com/@dkmaraga"
    }
  ]

  # Layout classes for the 5-tile gallery collage, applied in order to the
  # media items fetched from the database.
  @gallery_layout [
    %{class: "col-span-2 row-span-2", height_class: "h-64 sm:h-full"},
    %{class: "", height_class: "h-44 sm:h-full"},
    %{class: "", height_class: "h-44 sm:h-full"},
    %{class: "", height_class: "h-44 sm:h-full"},
    %{class: "object-center", height_class: "h-44  sm:h-full"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    news_items = Content.list_published_posts(scope: :posts, limit: 4)
    gallery_images = build_gallery_images()
    videos = build_campaign_videos()
    events = Content.list_upcoming_events(limit: 3)
    featured_event = List.first(events)

    content = Content.list_settings_map("home.")
    stats = build_stats(content)

    # Auto-dismiss the upcoming-event popup after 10 minutes; the visitor can
    # also close it sooner with the X button.
    if connected?(socket) and featured_event do
      Process.send_after(self(), :close_event_modal, :timer.minutes(10))
    end

    {:ok,
     assign(socket,
       featured_event: featured_event,
       show_event_modal: featured_event != nil,
       page_title: Seo.default_title(),
       page_description: Seo.default_description(),
       canonical_url: Seo.site_url(),
       structured_data: Seo.home_structured_data(news_items),
       social_links: @social_links,
       news_items: news_items,
       stats: stats,
       videos: videos,
       events: events,
       gallery_images: gallery_images,
       selected_gallery_image: nil,
       subscribed: false,
       subscribe_error: nil,
       content: content
     )}
  end

  @impl true
  def handle_event("close_event_modal", _params, socket) do
    {:noreply, assign(socket, :show_event_modal, false)}
  end

  def handle_event("open_gallery_image", %{"id" => id}, socket) do
    selected = Enum.find(socket.assigns.gallery_images, &(to_string(&1.id) == id))

    {:noreply, assign(socket, :selected_gallery_image, selected)}
  end

  def handle_event("close_gallery_image", _params, socket) do
    {:noreply, assign(socket, :selected_gallery_image, nil)}
  end

  def handle_event("subscribe_email", %{"email" => email}, socket) do
    case Volunteers.create_volunteer(%{
           email: email,
           additional_info: "Newsletter subscriber (website)"
         }) do
      {:ok, volunteer} ->
        WelcomeNotifier.deliver_welcome_email(volunteer.email)
        {:noreply, assign(socket, subscribed: true, subscribe_error: nil)}

      {:error, changeset} ->
        # An already-registered email is still a "success" for the visitor.
        if already_subscribed?(changeset) do
          {:noreply, assign(socket, subscribed: true, subscribe_error: nil)}
        else
          {:noreply,
           assign(socket,
             subscribed: false,
             subscribe_error: "Please enter a valid email address."
           )}
        end
    end
  end

  defp already_subscribed?(%Ecto.Changeset{errors: errors}) do
    Enum.any?(errors, fn
      {:email, {_message, opts}} -> Keyword.get(opts, :constraint) == :unique
      _ -> false
    end)
  end

  @impl true
  def handle_info(:close_event_modal, socket) do
    {:noreply, assign(socket, :show_event_modal, false)}
  end

  defp build_campaign_videos do
    case Content.list_published_media_items(media_type: "video") do
      [] ->
        Enum.map(@fallback_videos, &Map.put(&1, :href, "/media/videos"))

      items ->
        Enum.map(items, fn item ->
          %{
            title: item.title,
            thumb: item.image_url || "/images/gallery/1.jpg",
            href: "/media/videos"
          }
        end)
    end
  end

  defp build_gallery_images do
    Content.list_landing_media_items()
    |> Enum.take(length(@gallery_layout))
    |> Enum.zip(@gallery_layout)
    |> Enum.map(fn {item, layout} ->
      layout
      |> Map.put(:id, item.id)
      |> Map.put(:image, item.image_url)
      |> Map.put(:title, item.title)
      |> Map.put(:category, item.category)
      |> Map.put(:description, item.description)
    end)
  end

  defp build_stats(content) do
    [
      %{
        value: get_content(content, "home.stats.stat1_value", "1,250"),
        label: get_content(content, "home.stats.stat1_label", "Judgments"),
        description:
          get_content(
            content,
            "home.stats.stat1_description",
            "Decisions that shaped Kenya's law"
          )
      },
      %{
        value: get_content(content, "home.stats.stat2_value", "#1"),
        label: get_content(content, "home.stats.stat2_label", "In Africa"),
        description:
          get_content(
            content,
            "home.stats.stat2_description",
            "Annulled a presidential election"
          ),
        badge: get_content(content, "home.stats.stat2_badge", "Historic First")
      },
      %{
        value: get_content(content, "home.stats.stat3_value", "47"),
        label: get_content(content, "home.stats.stat3_label", "Counties"),
        description:
          get_content(
            content,
            "home.stats.stat3_description",
            "Justice delivered to every corner"
          )
      },
      %{
        value: get_content(content, "home.stats.stat4_value", "0"),
        label: get_content(content, "home.stats.stat4_label", "Tolerance"),
        description:
          get_content(content, "home.stats.stat4_description", "For corruption & impunity")
      }
    ]
  end

  # Returns the setting value, falling back to the default when the key is
  # absent or the stored value is an empty string.
  defp get_content(content, key, default) do
    case Map.get(content, key) do
      nil -> default
      "" -> default
      value -> value
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="top" class="min-h-screen bg-white">
      <.upcoming_event_modal :if={@show_event_modal && @featured_event} event={@featured_event} />
      <.site_header />
      <.hero_section content={@content} />
      <.donate_section content={@content} />
      <.events_section events={@events} content={@content} />
      <.mission_section content={@content} />
      <.documentary_section content={@content} />
      <.news_section news_items={@news_items} content={@content} />
      <.newsletter_section
        stats={@stats}
        content={@content}
        subscribed={@subscribed}
        subscribe_error={@subscribe_error}
      />
      <%!-- <.shop_section shop_items={@shop_items} /> --%>
      <.agenda_section videos={@videos} content={@content} />
      <.gallery_section gallery_images={@gallery_images} />
      <.site_footer id="footer" />

      <.modal
        :if={@selected_gallery_image}
        id="home-gallery-lightbox"
        show
        on_cancel={JS.push("close_gallery_image")}
      >
        <img
          src={@selected_gallery_image.image}
          alt={@selected_gallery_image.title}
          class="max-h-[70vh] w-full rounded-[6px] object-contain"
        />
        <div class="mt-5">
          <span class="font-head text-xs uppercase tracking-[0.18em] text-crimson">
            {@selected_gallery_image.category}
          </span>
          <h3 class="mt-1 font-head text-2xl uppercase tracking-[0.04em] text-blueink">
            {@selected_gallery_image.title}
          </h3>
          <p
            :if={present?(@selected_gallery_image.description)}
            class="mt-3 text-base leading-7 text-grayink"
          >
            {@selected_gallery_image.description}
          </p>
          <a
            href={@selected_gallery_image.image}
            target="_blank"
            rel="noopener"
            class="mt-5 inline-flex items-center gap-2 font-head text-xs font-semibold uppercase tracking-[0.16em] text-crimson transition hover:text-blueink"
          >
            Open full size <.icon name="hero-arrow-top-right-on-square-mini" class="h-4 w-4" />
          </a>
        </div>
      </.modal>
    </div>
    """
  end

  attr :content, :map, default: %{}

  defp hero_section(assigns) do
    assigns =
      assign(assigns,
        bg_image: get_content(assigns.content, "home.hero.bg_image", "/images/IMG_2075.jpg"),
        title: get_content(assigns.content, "home.hero.title", "David Kenani Maraga -  2027"),
        tagline:
          get_content(assigns.content, "home.hero.tagline", "Reset. Restore. Rebuild Kenya."),
        cta1_label: get_content(assigns.content, "home.hero.cta1_label", "Read More"),
        cta1_href: get_content(assigns.content, "home.hero.cta1_href", "#mission"),
        cta2_label:
          get_content(assigns.content, "home.hero.cta2_label", "Jiandikishe Kupiga Kura"),
        cta2_href:
          get_content(
            assigns.content,
            "home.hero.cta2_href",
            "https://www.iebc.or.ke/iebc/?constituency"
          )
      )

    ~H"""
    <section
      id="hero"
      class="relative overflow-hidden bg-cover"
      style={"background-position: center 30%; background-image: url('#{@bg_image}');"}
    >
      <div aria-hidden="true" class="absolute inset-0">
        <div class="hero-color-slide hero-color-slide-left"></div>
        <div class="hero-color-slide hero-color-slide-right"></div>
      </div>

      <div class="relative z-10 mx-auto flex min-h-[100vh] w-full max-w-container items-center px-4 lg:px-6">
        <div class="w-full text-center">
          <h3 class="font-head text-[40px] font-semibold uppercase leading-[1.05] tracking-[3px] text-white md:text-[60px] lg:text-[76px]">
            {@title}
          </h3>
          <h1 class="mt-4 font-serifi text-3xl italic text-white sm:text-4xl md:text-5xl lg:text-6xl">
            {@tagline}
          </h1>

          <div class="mt-12 flex flex-col items-stretch gap-4 sm:flex-row sm:items-center sm:gap-0">
            <div class="flex sm:w-1/2 sm:justify-end sm:pr-3">
              <a
                href={@cta1_href}
                class="inline-flex w-full min-w-[190px] items-center justify-center rounded-full bg-white px-8 py-3.5 font-head text-[13px] font-bold uppercase tracking-[0.2em] text-blueink transition duration-300 hover:bg-crimson sm:w-auto"
              >
                {@cta1_label}
              </a>
            </div>
            <div class="flex sm:w-1/2 sm:justify-start sm:pl-3">
              <a
                href={@cta2_href}
                rel="noopener"
                target="_blank"
                class="inline-flex w-full min-w-[190px] items-center justify-center rounded-full border-2 border-white px-8 py-3.5 font-head text-[13px] font-bold uppercase tracking-[0.2em] text-white transition duration-300 hover:bg-white hover:text-blueink sm:w-auto"
              >
                {@cta2_label}
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr :content, :map, default: %{}

  defp donate_section(assigns) do
    assigns =
      assign(assigns,
        donate_url:
          get_content(
            assigns.content,
            "home.donate.button_url",
            "https://donations.davidmaraga.com/"
          ),
        volunteer_url:
          get_content(
            assigns.content,
            "home.donate.volunteer_url",
            "https://www.davidmaraga.com/volunteer"
          )
      )

    ~H"""
    <section class="relative w-full overflow-hidden bg-ghost px-4 shadow-[0_10px_50px_#0000000a]">
      <div class="mx-auto flex max-w-container flex-col items-top justify-center gap-8 py-8 lg:flex-row lg:justify-between">
        <div class="flex  gap-3">
          <h3 class="font-head text-6xl uppercase text-blueink">donate</h3>
          <h3 class="font-head text-6xl uppercase text-crimson">today</h3>
        </div>

        <div class="flex flex-col items-center gap-5 sm:items-end">
          <div class="flex flex-wrap items-center justify-center gap-3">
            <.donation_chip amount="KES 50" />
            <.donation_chip amount="KES 100" />
            <.donation_chip amount="KES 200" />
            <.donation_chip amount="KES 500" />
            <.donation_chip amount="KES 1000" />

            <input
              type="text"
              placeholder="Other"
              class="w-24 rounded-[5px] border border-[#e6e6e6] bg-white px-4 py-3 text-ink outline-none focus:border-blueink"
            />
          </div>

          <div class="flex flex-wrap items-center justify-center gap-3 sm:justify-end">
            <a
              type="button"
              href={@donate_url}
              rel="noopener"
              target="_blank"
              class="rounded-[5px] border-2 border-red-500 bg-red-500 px-[44px] py-5 text-lg font-semibold text-white transition hover:bg-transparent hover:text-red-500"
            >
              Donate Now
            </a>
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr :content, :map, default: %{}

  defp mission_section(assigns) do
    assigns =
      assign(assigns,
        image: get_content(assigns.content, "home.mission.image", "/images/IMG_2052.jpg"),
        heading_prefix: get_content(assigns.content, "home.mission.heading_prefix", "A man of"),
        heading_accent1:
          get_content(assigns.content, "home.mission.heading_accent1", "integrity"),
        heading_mid:
          get_content(
            assigns.content,
            "home.mission.heading_mid",
            "for a time that demands"
          ),
        heading_accent2:
          get_content(assigns.content, "home.mission.heading_accent2", "character."),
        quote:
          get_content(
            assigns.content,
            "home.mission.quote",
            "David Maraga — the judge who annulled a presidential election and proved no one is above the law. A reformer who digitized courts, expanded access to justice, and authored over 1,250 judgments. Fearless, principled, and relentless — Kenya's greatest judicial guardian"
          ),
        cta_href: get_content(assigns.content, "home.mission.cta_href", "#footer")
      )

    ~H"""
    <section
      id="mission"
      class="relative overflow-hidden bg-white py-20 lg:py-28"
      style="background-image: radial-gradient(#dfe3ee 1.6px, transparent 1.7px); background-size: 24px 24px; background-position: center;"
    >
      <div
        id="mission-panel"
        phx-hook="RevealOnScroll"
        class="reveal-on-scroll relative mx-auto flex max-w-container flex-col items-center gap-0 px-4 lg:flex-row lg:items-center"
      >
        <div class="w-full lg:w-[58%]">
          <img
            src={@image}
            alt="David Maraga"
            loading="lazy"
            class="h-[360px] w-full rounded-[5px] object-cover object-[center_30%] shadow-2xl sm:h-[620px] lg:h-[820px]"
          />
        </div>

        <div class="relative z-10 -mt-12 w-[92%] rounded-[5px] bg-blueink px-8 py-10 shadow-2xl sm:px-10 lg:-ml-[14%] lg:mt-0 lg:w-[44%] lg:px-12 lg:py-12">
          <h2 class="font-head text-4xl uppercase text-white md:text-5xl">
            {@heading_prefix} <span class="text-crimson">{@heading_accent1}</span>
            {@heading_mid} <span class="text-crimson">{@heading_accent2}</span>
          </h2>

          <p class="mt-4 font-serifi text-xl italic leading-relaxed tracking-[.5px] text-white">
            " {@quote}"
          </p>

          <a
            href={@cta_href}
            class="mt-8 inline-flex items-center gap-2 font-head text-[15px] font-semibold uppercase tracking-wide text-white transition hover:text-crimson"
          >
            Bio
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
              <line x1="5" y1="12" x2="19" y2="12" />
              <polyline points="12 5 19 12 12 19" />
            </svg>
          </a>
        </div>
      </div>
    </section>
    """
  end

  attr :content, :map, default: %{}

  defp documentary_section(assigns) do
    assigns =
      assign(assigns,
        title_prefix:
          get_content(assigns.content, "home.documentary.title_prefix", "The Maraga Story"),
        title_accent:
          get_content(assigns.content, "home.documentary.title_accent", "Documentary"),
        description:
          get_content(
            assigns.content,
            "home.documentary.description",
            "The first autobiographical documentary on David Maraga, produced with NTV."
          ),
        youtube_url:
          get_content(
            assigns.content,
            "home.documentary.youtube_url",
            "https://www.youtube.com/embed/-2QefPbyXrQ"
          )
      )

    ~H"""
    <section id="documentary" class="bg-white py-20 lg:py-28">
      <div class="mx-auto max-w-container px-4">
        <.section_heading
          title={"#{@title_prefix} #{@title_accent}"}
          accent={@title_accent}
          description={@description}
        />

        <div
          id="documentary-frame"
          phx-hook="RevealOnScroll"
          class="reveal-on-scroll mx-auto mt-10 max-w-4xl overflow-hidden rounded-[5px] shadow-2xl"
        >
          <div class="relative w-full" style="padding-top: 56.25%;">
            <iframe
              class="absolute inset-0 h-full w-full"
              src={@youtube_url}
              title="David Maraga: The Autobiographical Documentary"
              frameborder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              referrerpolicy="strict-origin-when-cross-origin"
              allowfullscreen
            >
            </iframe>
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr :news_items, :list, required: true
  attr :content, :map, default: %{}

  defp news_section(assigns) do
    assigns =
      assign(assigns,
        title_prefix: get_content(assigns.content, "home.news.title_prefix", "latest"),
        title_accent: get_content(assigns.content, "home.news.title_accent", "News"),
        description:
          get_content(
            assigns.content,
            "home.news.description",
            "Get the latest updates on the campaign trail, policy positions, and more."
          )
      )

    ~H"""
    <section id="news" phx-hook="RevealOnScroll" class="reveal-on-scroll bg-ghost py-20">
      <div class="mx-auto max-w-container px-4">
        <.section_heading
          title={"#{@title_prefix} #{@title_accent}"}
          accent={@title_accent}
          description={@description}
        />

        <div
          :if={Enum.empty?(@news_items)}
          class="rounded-[8px] bg-white px-8 py-12 text-center shadow-[0_15px_40px_rgba(15,30,80,0.08)]"
        >
          <h3 class="font-head text-2xl uppercase tracking-[0.08em] text-blueink">
            No blogs published yet
          </h3>
          <p class="mx-auto mt-3 max-w-2xl text-base leading-7 text-grayink">
            Log into the admin area, create your first post, and it will appear here automatically.
          </p>
        </div>

        <div :if={not Enum.empty?(@news_items)} class="grid grid-cols-1 gap-7 md:grid-cols-2">
          <.news_card :for={item <- @news_items} item={item} />
        </div>
      </div>
    </section>
    """
  end

  attr :stats, :list, required: true
  attr :content, :map, default: %{}
  attr :subscribed, :boolean, default: false
  attr :subscribe_error, :string, default: nil

  defp newsletter_section(assigns) do
    assigns =
      assign(assigns,
        bg_image:
          get_content(
            assigns.content,
            "home.newsletter.bg_image",
            "/images/maraga-town-old.jpg"
          ),
        eyebrow: get_content(assigns.content, "home.newsletter.eyebrow", "Stay in the loop"),
        heading:
          get_content(assigns.content, "home.newsletter.heading", "Subscribe to Our Emails"),
        description:
          get_content(
            assigns.content,
            "home.newsletter.description",
            "Get campaign updates, rally announcements, and policy highlights delivered straight to your inbox."
          ),
        stats_eyebrow: get_content(assigns.content, "home.stats.eyebrow", "Kenya 2027"),
        stats_heading: get_content(assigns.content, "home.stats.heading", "David Maraga"),
        stats_tagline:
          get_content(
            assigns.content,
            "home.stats.tagline",
            "For President · Integrity · Justice · Nation"
          ),
        stats_motto: get_content(assigns.content, "home.stats.motto", "Ukatiba Ndio Tiba")
      )

    ~H"""
    <section id="newsletter">
      <div class="relative bg-cover bg-center" style={"background-image: url('#{@bg_image}');"}>
        <div class="absolute inset-0 bg-black/60"></div>

        <div
          id="newsletter-callout"
          phx-hook="RevealOnScroll"
          class="reveal-on-scroll relative z-10 mx-auto flex max-w-container flex-col items-center px-4 py-28 text-center"
        >
          <svg
            class="mb-5 h-12 w-12 text-white"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <rect x="3" y="5" width="18" height="14" rx="2" />
            <path d="m3 7 9 6 9-6" />
          </svg>

          <h3 class="font-serifi text-2xl italic text-white">{@eyebrow}</h3>
          <h2 class="mt-2 font-head text-4xl uppercase tracking-[.5px] text-white md:text-5xl">
            {@heading}
          </h2>
          <p class="mt-5 max-w-2xl text-base leading-7 text-white/80 sm:text-lg">
            {@description}
          </p>

          <div :if={@subscribed} class="mt-8 flex items-center gap-2 text-lg text-white">
            <svg
              class="h-6 w-6 text-white"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <path d="M20 6 9 17l-5-5" />
            </svg>
            Thanks! You're on the list — we'll be in touch.
          </div>

          <form
            :if={!@subscribed}
            phx-submit="subscribe_email"
            class="mt-8 flex w-full max-w-xl flex-col items-stretch gap-3 sm:flex-row"
          >
            <input
              type="email"
              name="email"
              required
              placeholder="Enter your email address"
              class="w-full flex-1 rounded-[5px] border border-white/30 bg-white/95 px-5 py-[18px] text-base text-blueink outline-none placeholder:text-grayink focus:border-crimson"
            />
            <button
              type="submit"
              class="inline-flex items-center justify-center gap-2 rounded-[5px] bg-crimson px-[30px] py-[18px] font-head text-[15px] font-semibold uppercase tracking-wide text-white transition hover:bg-blueink"
            >
              Subscribe
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
                <line x1="5" y1="12" x2="19" y2="12" />
                <polyline points="12 5 19 12 12 19" />
              </svg>
            </button>
          </form>

          <p :if={@subscribe_error} class="mt-3 text-sm text-white">
            {@subscribe_error}
          </p>
        </div>
      </div>

      <div class="bg-[#0b7600] py-20 text-white">
        <div class="mx-auto max-w-[1040px] px-4">
          <div class="text-center">
            <div class="mx-auto h-2 w-full max-w-[620px] overflow-hidden rounded-full bg-[#d61f26]">
              <div class="grid h-full grid-cols-4">
                <span class="bg-[#d61f26]"></span>
                <span class="bg-black"></span>
                <span class="bg-white"></span>
                <span class="bg-[#d61f26]"></span>
              </div>
            </div>

            <p class="mt-10 font-head text-sm uppercase tracking-[0.45em] text-[#d0b216] sm:text-base">
              {@stats_eyebrow}
            </p>
            <h2 class="mt-4 font-head text-4xl font-bold uppercase tracking-[0.06em] text-white sm:text-5xl md:text-6xl">
              {@stats_heading}
            </h2>
            <p class="mt-4 font-head text-sm uppercase tracking-[0.45em] text-white/70 sm:text-base">
              {@stats_tagline}
            </p>
            <div class="mx-auto mt-8 h-1 w-24 rounded-full bg-[#d0b216]"></div>
          </div>

          <div class="mx-auto mt-14 grid w-[100%] grid-cols-1 gap-8 md:grid-cols-2 xl:grid-cols-4">
            <.stat_card :for={stat <- @stats} stat={stat} />
          </div>

          <p class="mt-14 text-center font-head text-2xl uppercase tracking-[0.28em] text-white/72 sm:text-3xl md:text-4xl">
            {@stats_motto}
          </p>
        </div>
      </div>
    </section>
    """
  end

  attr :events, :list, required: true
  attr :content, :map, default: %{}

  defp events_section(assigns) do
    assigns =
      assign(assigns,
        events_title_prefix: get_content(assigns.content, "home.events.title_prefix", "Upcoming"),
        events_title_accent: get_content(assigns.content, "home.events.title_accent", "Events"),
        events_description:
          get_content(
            assigns.content,
            "home.events.description",
            "Follow the latest news and updates from the campaign trail ."
          )
      )

    ~H"""
    <section id="events" class="bg-ghost py-20">
      <div class="mx-auto max-w-container px-4">
        <.section_heading
          title={"#{@events_title_prefix} #{@events_title_accent}"}
          accent={@events_title_accent}
          description={@events_description}
        />

        <div :if={@events != []} class="grid grid-cols-1 gap-7 md:grid-cols-3">
          <.event_card :for={event <- @events} event={event} />
        </div>

        <p :if={@events == []} class="text-center text-base leading-7 text-grayink">
          No upcoming events scheduled yet — check the calendar for updates.
        </p>

        <div class="mt-10 text-center">
          <.link
            navigate={~p"/events"}
            class="inline-flex items-center justify-center rounded-full bg-blueink px-8 py-3.5 font-head text-[13px] font-bold uppercase tracking-[0.2em] text-white transition duration-300 hover:bg-crimson"
          >
            View Full Calendar
          </.link>
        </div>
      </div>
    </section>
    """
  end

  attr :videos, :list, required: true
  attr :content, :map, default: %{}

  defp agenda_section(assigns) do
    assigns =
      assign(assigns,
        videos_title_prefix:
          get_content(assigns.content, "home.agenda.title_prefix", "Watch the"),
        videos_title_accent: get_content(assigns.content, "home.agenda.title_accent", "Campaign"),
        videos_description:
          get_content(
            assigns.content,
            "home.agenda.description",
            "Catch the latest moments from the trail — tap any clip to watch on YouTube and social media."
          )
      )

    ~H"""
    <section id="agenda" class="bg-white py-20">
      <div class="mx-auto max-w-container px-4">
        <.section_heading
          title={"#{@videos_title_prefix} #{@videos_title_accent}"}
          accent={@videos_title_accent}
          description={@videos_description}
        />
      </div>

      <.video_carousel videos={@videos} />
    </section>
    """
  end

  attr :gallery_images, :list, required: true

  defp gallery_section(assigns) do
    ~H"""
    <section id="gallery" phx-hook="RevealOnScroll" class="reveal-on-scroll bg-white pb-20">
      <div class="mx-auto max-w-container px-4">
        <div class="grid h-auto grid-cols-2 gap-0 sm:h-[600px] sm:grid-cols-4 sm:grid-rows-2">
          <.gallery_item :for={image <- @gallery_images} image={image} />
        </div>
      </div>
    </section>
    """
  end

  attr :title, :string, required: true
  attr :accent, :string, required: true
  attr :description, :string, required: true

  defp section_heading(assigns) do
    base_title = String.trim_trailing(assigns.title, assigns.accent)

    assigns =
      assigns
      |> assign(:base_title, String.trim(base_title))

    ~H"""
    <div class="mb-12 text-center">
      <h2 class="font-head text-4xl uppercase text-blueink md:text-5xl">
        {@base_title} <span class="text-crimson">{@accent}</span>
      </h2>
      <p class="mx-auto mt-2 max-w-xl text-base leading-7 text-grayink">{@description}</p>
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
          class="h-[300px] w-full object-cover object-[center_30%] transition duration-500 group-hover:scale-105"
        />
      </.link>

      <div class="flex flex-1 flex-col p-7">
        <div class="flex items-center gap-2 text-xs">
          <span class="font-bold uppercase tracking-[2px] text-crimson">
            {format_post_date(@item.published_at)}
          </span>
          <span class="text-grayink">|</span>
          <.link
            navigate={~p"/blog/#{@item.slug}"}
            class="font-bold uppercase tracking-[1px] text-grayink transition hover:text-crimson"
          >
            {@item.category}
          </.link>
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

  attr :event, :map, required: true

  defp upcoming_event_modal(assigns) do
    ~H"""
    <div
      id="upcoming-event-modal"
      class="fixed inset-0 z-[100] flex items-center justify-center px-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="upcoming-event-title"
    >
      <div
        class="absolute inset-0 bg-black/60 backdrop-blur-sm"
        phx-click="close_event_modal"
        aria-hidden="true"
      >
      </div>

      <div class="relative w-full max-w-lg overflow-hidden rounded-[14px] bg-white shadow-2xl">
        <button
          type="button"
          phx-click="close_event_modal"
          class="absolute right-3 top-3 z-10 flex h-9 w-9 items-center justify-center rounded-full bg-white/90 text-blueink shadow-md transition hover:bg-crimson hover:text-white"
          aria-label="Close"
        >
          <svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 6l12 12M18 6L6 18" />
          </svg>
        </button>

        <img
          :if={@event.image_url}
          src={@event.image_url}
          alt={@event.title}
          class="h-48 w-full object-cover"
        />

        <div class="p-6 sm:p-8">
          <p class="font-head text-sm font-bold uppercase tracking-[0.2em] text-crimson">
            Upcoming Event
          </p>

          <h3
            id="upcoming-event-title"
            class="mt-3 font-head text-3xl uppercase leading-tight tracking-[0.5px] text-blueink"
          >
            {@event.title}
          </h3>

          <div class="mt-4 flex items-center gap-3 text-grayink">
            <div class="flex shrink-0 flex-col items-center justify-center rounded-[5px] bg-blueink px-4 py-2 text-white">
              <span class="font-head text-2xl leading-none">
                {Calendar.strftime(@event.starts_at, "%d")}
              </span>
              <span class="font-head text-xs uppercase tracking-wide">
                {Calendar.strftime(@event.starts_at, "%b")}
              </span>
            </div>
            <div class="text-base leading-6">
              <p>{Calendar.strftime(@event.starts_at, "%A, %d %B %Y")}</p>
              <p :if={!@event.all_day}>{Calendar.strftime(@event.starts_at, "%-I:%M %p")}</p>
              <p :if={@event.location} class="text-grayink/80">{@event.location}</p>
            </div>
          </div>

          <p :if={@event.description} class="mt-4 line-clamp-3 text-base leading-7 text-grayink">
            {@event.description}
          </p>

          <.link
            navigate={~p"/events"}
            class="mt-6 inline-flex w-full items-center justify-center rounded-full bg-crimson px-8 py-3 font-head text-[13px] font-bold uppercase tracking-[0.2em] text-white transition hover:bg-blueink"
          >
            View Event
          </.link>
        </div>
      </div>
    </div>
    """
  end

  attr :event, :map, required: true

  defp event_card(assigns) do
    ~H"""
    <article class="group flex flex-col gap-4">
      <.link
        :if={@event.image_url}
        navigate={~p"/events"}
        class="block overflow-hidden rounded-[10px]"
      >
        <img
          src={@event.image_url}
          alt={@event.title}
          class="h-48 w-full object-cover transition duration-500 group-hover:scale-105"
          loading="lazy"
        />
      </.link>

      <div class="flex items-stretch gap-4">
        <div class="flex shrink-0 flex-col items-center justify-center rounded-[5px] bg-blueink px-4 py-3 text-white">
          <div class="font-head text-3xl leading-none">
            {Calendar.strftime(@event.starts_at, "%d")}
          </div>
          <div class="font-head text-sm uppercase tracking-wide">
            {Calendar.strftime(@event.starts_at, "%b")}
          </div>
        </div>

        <div class="flex-1">
          <.link navigate={~p"/events"}>
            <h4 class="mt-0 font-head text-2xl uppercase tracking-[.5px] text-blueink transition hover:text-crimson">
              {@event.title}
            </h4>
          </.link>
          <p :if={@event.location} class="mt-1 text-base leading-7 text-grayink">
            {@event.location}
          </p>
        </div>
      </div>
    </article>
    """
  end

  attr :videos, :list, required: true

  defp video_carousel(assigns) do
    ~H"""
    <div class="video-marquee-wrap relative overflow-hidden">
      <div class="pointer-events-none absolute inset-y-0 left-0 z-10 w-12 bg-gradient-to-r from-white to-transparent sm:w-24">
      </div>
      <div class="pointer-events-none absolute inset-y-0 right-0 z-10 w-12 bg-gradient-to-l from-white to-transparent sm:w-24">
      </div>

      <div class="video-marquee flex w-max gap-6 px-3">
        <.video_card :for={video <- @videos ++ @videos} video={video} />
      </div>
    </div>
    """
  end

  attr :video, :map, required: true

  defp video_card(assigns) do
    ~H"""
    <.link
      navigate={@video.href}
      class="group relative block h-[220px] w-[320px] shrink-0 overflow-hidden rounded-[10px] shadow-[0_10px_30px_#0006] sm:h-[260px] sm:w-[420px]"
      style={"background-image: url('#{@video.thumb}'); background-size: cover; background-position: center;"}
    >
      <div class="absolute inset-0 bg-black/50 transition group-hover:bg-black/35"></div>
      <div class="absolute inset-0 flex items-center justify-center">
        <span class="flex h-16 w-16 items-center justify-center rounded-full bg-white shadow-lg transition group-hover:scale-110">
          <svg
            class="ml-1 h-7 w-7 text-crimson"
            viewBox="0 0 24 24"
            fill="currentColor"
            aria-hidden="true"
          >
            <polygon points="6 4 20 12 6 20 6 4" />
          </svg>
        </span>
      </div>
      <div class="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/80 to-transparent p-4">
        <p class="font-head text-sm uppercase tracking-[0.1em] text-white">{@video.title}</p>
      </div>
    </.link>
    """
  end

  attr :stat, :map, required: true

  defp stat_card(assigns) do
    ~H"""
    <article class="relative rounded-[10px] border-2 border-[#b89e10] px-6 py-10 text-center shadow-[0_0_0_1px_rgba(255,255,255,0.03)] sm:px-8">
      <span
        :if={Map.get(@stat, :badge)}
        class="absolute left-1/2 top-0 -translate-x-1/2 -translate-y-1/2 rounded-[4px] bg-[#d0b216] px-4 py-1 font-head text-sm font-bold uppercase tracking-[0.2em] text-[#0b7600]"
      >
        {Map.get(@stat, :badge)}
      </span>

      <div class="font-head text-5xl font-bold leading-none text-white sm:text-6xl">
        {@stat.value}
      </div>
      <div class="mt-4 font-head text-2xl font-semibold uppercase tracking-wide text-[#d0b216]">
        {@stat.label}
      </div>
      <p class="mt-4 font-head text-base uppercase tracking-[0.18em] text-white/75 sm:text-lg">
        {@stat.description}
      </p>
    </article>
    """
  end

  attr :image, :map, required: true

  defp gallery_item(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="open_gallery_image"
      phx-value-id={@image.id}
      class={["group relative block overflow-hidden text-left", @image.class]}
      aria-label={"Open #{@image.title}"}
    >
      <img
        src={@image.image}
        alt={@image.title}
        loading="lazy"
        class={[
          @image.height_class,
          "w-full object-cover object-[center_30%] transition duration-500 group-hover:scale-105"
        ]}
      />
      <span class="absolute inset-0 flex items-center justify-center bg-blueink/0 text-4xl font-light text-white opacity-0 transition group-hover:bg-blueink/60 group-hover:opacity-100 sm:text-5xl">
        +
      </span>
    </button>
    """
  end

  attr :amount, :string, required: true

  defp donation_chip(assigns) do
    ~H"""
    <label class="cursor-pointer">
      <input type="checkbox" class="peer hidden" />
      <span class="block rounded-[5px] border border-[#e6e6e6] bg-white px-5 py-3 font-head font-medium text-blueink transition peer-checked:border-crimson peer-checked:bg-crimson peer-checked:text-white">
        {@amount}
      </span>
    </label>
    """
  end

  defp format_post_date(nil), do: "Draft"

  defp format_post_date(%DateTime{} = published_at),
    do: Calendar.strftime(published_at, "%b %-d, %Y")

  defp present?(nil), do: false
  defp present?(value) when is_binary(value), do: String.trim(value) != ""
end
