defmodule MaragaInfoWeb.HomeLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfo.Content.Post
  alias MaragaInfoWeb.Seo

  @social_links [
    %{name: "x", href: "https://x.com/dkmaraga", label: "X"},
    %{name: "instagram", href: "https://www.instagram.com/maraga2027", label: "Instagram"},
    %{name: "youtube", href: "https://www.youtube.com/@dkmaraga", label: "YouTube"}
  ]

  @stats [
    %{
      value: "1,250",
      label: "Judgments",
      description: "Decisions that shaped Kenya's law"
    },
    %{
      value: "#1",
      label: "In Africa",
      description: "Annulled a presidential election",
      badge: "Historic First"
    },
    %{
      value: "47",
      label: "Counties",
      description: "Justice delivered to every corner"
    },
    %{
      value: "0",
      label: "Tolerance",
      description: "For corruption & impunity"
    }
  ]

  @shop_items [
    %{
      name: "American Flag",
      price: "$ 20.00 USD",
      image: "https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=1080&q=80"
    },
    %{
      name: "Vote Badge",
      price: "$ 15.00 USD",
      image: "https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=1080&q=80"
    },
    %{
      name: "American Flags and Pins",
      price: "$ 20.00 USD",
      image: "https://images.unsplash.com/photo-1559521783-1d1599583485?w=1080&q=80"
    }
  ]

  @videos [
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

  @events [
    %{day: "16", month: "Jun", title: "State of Nation: The Way Forward – 16 June 2026"},
    %{day: "08", month: "Jun", title: "Nairobi National Park Protest – Maraga Arrested"},
    %{day: "25", month: "May", title: "Ukombozi Campaign Launch – Lodwar, Turkana"}
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

    {:ok,
     assign(socket,
       page_title: Seo.default_title(),
       page_description: Seo.default_description(),
       canonical_url: Seo.site_url(),
       structured_data: Seo.home_structured_data(news_items),
       social_links: @social_links,
       news_items: news_items,
       stats: @stats,
       shop_items: @shop_items,
       videos: @videos,
       events: @events,
       gallery_images: gallery_images
     )}
  end

  # Pairs the published media items with the collage layout classes so the
  # gallery shows exactly five images sourced from the database.
  defp build_gallery_images do
    Content.list_landing_media_items()
    |> Enum.take(length(@gallery_layout))
    |> Enum.zip(@gallery_layout)
    |> Enum.map(fn {item, layout} -> Map.put(layout, :image, item.image_url) end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="top" class="min-h-screen bg-white">
      <.site_header />
      <.hero_section />
      <.donate_section />
      <.mission_section />
      <.documentary_section />
      <.news_section news_items={@news_items} />
      <.newsletter_section stats={@stats} />
      <%!-- <.shop_section shop_items={@shop_items} /> --%>
      <.agenda_section events={@events} videos={@videos} />
      <.gallery_section gallery_images={@gallery_images} />
      <.site_footer id="footer" />
    </div>
    """
  end

  defp hero_section(assigns) do
    ~H"""
    <section
      id="hero"
      class="relative overflow-hidden bg-cover"
      style="background-position: center 30%; background-image: url('/images/IMG_2075.jpg');"
    >
      <div aria-hidden="true" class="absolute inset-0">
        <div class="hero-color-slide hero-color-slide-left"></div>
        <div class="hero-color-slide hero-color-slide-right"></div>
      </div>

      <div class="relative z-10 mx-auto flex min-h-[100vh] w-full max-w-container items-center px-4 lg:px-6">
        <div class="w-full text-center">
          <h3 class="font-serifi text-3xl italic text-white sm:text-4xl md:text-5xl lg:text-6xl">
            Presidential Candidate 2027
          </h3>
          <h1 class="mt-4 font-head text-[40px] font-semibold uppercase leading-[1.05] tracking-[3px] text-white md:text-[60px] lg:text-[76px]">
            Reset. Restore. <br /> Rebuild Kenya.
          </h1>

          <div class="mt-12 flex flex-col items-stretch gap-4 sm:flex-row sm:items-center sm:gap-0">
            <div class="flex sm:w-1/2 sm:justify-end sm:pr-3">
              <a
                href="#mission"
                class="inline-flex w-full min-w-[190px] items-center justify-center rounded-full bg-white px-8 py-3.5 font-head text-[13px] font-bold uppercase tracking-[0.2em] text-blueink transition duration-300 hover:bg-crimson sm:w-auto"
              >
                Read More
              </a>
            </div>
            <div class="flex sm:w-1/2 sm:justify-start sm:pl-3">
              <a
                href="https://www.iebc.or.ke/"
                rel="noopener"
                target="_blank"
                class="inline-flex w-full min-w-[190px] items-center justify-center rounded-full border-2 border-white px-8 py-3.5 font-head text-[13px] font-bold uppercase tracking-[0.2em] text-white transition duration-300 hover:bg-white hover:text-blueink sm:w-auto"
              >
                Jiandikishe Kupiga Kura
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  defp donate_section(assigns) do
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
              href="https://donations.davidmaraga.com/"
              rel="noopener"
              target="_blank"
              class="rounded-[5px] border-2 border-red-500 bg-red-500 px-[44px] py-5 text-lg font-semibold text-white transition hover:bg-transparent hover:text-red-500"
            >
              Donate Now
            </a>
            <a
              type="button"
              href="https://www.davidmaraga.com/volunteer"
              rel="noopener"
              target="_blank"
              class="rounded-[5px] border-2 border-crimson bg-crimson px-[44px] py-5 text-lg font-semibold text-white transition hover:bg-transparent hover:text-crimson"
            >
              Volunteer
            </a>
          </div>
        </div>
      </div>
    </section>
    """
  end

  defp mission_section(assigns) do
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
            src="/images/IMG_2052.jpg"
            alt="Government building with national flag"
            loading="lazy"
            class="h-[360px] w-full rounded-[5px] object-cover object-[center_30%] shadow-2xl sm:h-[620px] lg:h-[820px]"
          />
        </div>

        <div class="relative z-10 -mt-12 w-[92%] rounded-[5px] bg-blueink px-8 py-10 shadow-2xl sm:px-10 lg:-ml-[14%] lg:mt-0 lg:w-[44%] lg:px-12 lg:py-12">
          <h2 class="font-head text-4xl uppercase text-white md:text-5xl">
            A man of <span class="text-crimson">integrity</span>
            for a time that demands <span class="text-crimson"> character. </span>
          </h2>

          <p class="mt-4 font-serifi text-xl italic leading-relaxed tracking-[.5px] text-white">
            "
            David Maraga — the judge who annulled a presidential election and proved no one is above the law. A reformer who digitized courts, expanded access to justice, and authored over 1,250 judgments. Fearless, principled, and relentless — Kenya's greatest judicial guardian"
          </p>

          <a
            href="#footer"
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

  defp documentary_section(assigns) do
    ~H"""
    <section id="documentary" class="bg-white py-20 lg:py-28">
      <div class="mx-auto max-w-container px-4">
        <.section_heading
          title="The Maraga Story"
          accent="Documentary"
          description="The first autobiographical documentary on David Maraga, produced with NTV."
        />

        <div
          id="documentary-frame"
          phx-hook="RevealOnScroll"
          class="reveal-on-scroll mx-auto mt-10 max-w-4xl overflow-hidden rounded-[5px] shadow-2xl"
        >
          <div class="relative w-full" style="padding-top: 56.25%;">
            <iframe
              class="absolute inset-0 h-full w-full"
              src="https://www.youtube.com/embed/-2QefPbyXrQ"
              title="David Maraga: The Autobiographical Documentary (NTV)"
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

  defp news_section(assigns) do
    ~H"""
    <section id="news" phx-hook="RevealOnScroll" class="reveal-on-scroll bg-ghost py-20">
      <div class="mx-auto max-w-container px-4">
        <.section_heading
          title="latest News"
          accent="News"
          description="Get the latest updates on the campaign trail, policy positions, and more."
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

  defp newsletter_section(assigns) do
    ~H"""
    <section id="newsletter">
      <div
        class="relative bg-cover bg-center"
        style="background-image: url('/images/justin-lagat-7e16OcueiNs-unsplash.jpg');"
      >
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

          <h3 class="font-serifi text-2xl italic text-white">Stay in the loop</h3>
          <h2 class="mt-2 font-head text-4xl uppercase tracking-[.5px] text-white md:text-5xl">
            Subscribe to the newsletter
          </h2>
          <p class="mt-5 max-w-2xl text-base leading-7 text-white/80 sm:text-lg">
            Get campaign updates, rally announcements, and policy highlights delivered straight to your inbox.
          </p>

          <a
            href="#footer"
            class="mt-8 inline-flex items-center gap-2 rounded-[5px] bg-crimson px-[30px] py-[18px] font-head text-[15px] font-semibold uppercase tracking-wide text-white transition hover:bg-blueink"
          >
            Subscribe For Updates
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
              Kenya 2027
            </p>
            <h2 class="mt-4 font-head text-4xl font-bold uppercase tracking-[0.06em] text-white sm:text-5xl md:text-6xl">
              David Maraga
            </h2>
            <p class="mt-4 font-head text-sm uppercase tracking-[0.45em] text-white/70 sm:text-base">
              For President · Integrity · Justice · Nation
            </p>
            <div class="mx-auto mt-8 h-1 w-24 rounded-full bg-[#d0b216]"></div>
          </div>

          <div class="mx-auto mt-14 grid w-[100%] grid-cols-1 gap-8 md:grid-cols-2 xl:grid-cols-4">
            <.stat_card :for={stat <- @stats} stat={stat} />
          </div>

          <p class="mt-14 text-center font-head text-base uppercase tracking-[0.35em] text-white/72 sm:text-lg">
            Ukatiba Ndio Tiba
          </p>
        </div>
      </div>
    </section>
    """
  end

  attr :shop_items, :list, required: true

  defp shop_section(assigns) do
    ~H"""
    <section id="shop" class="bg-white py-20">
      <div class="mx-auto max-w-container px-4">
        <.section_heading
          title="Shop for campaign"
          accent="campaign"
          description="The Brady Bunch the Brady Bunch that is the way we all go on got a dream"
        />

        <div class="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
          <.shop_card :for={item <- @shop_items} item={item} />
        </div>
      </div>
    </section>
    """
  end

  attr :events, :list, required: true
  attr :videos, :list, required: true

  defp agenda_section(assigns) do
    ~H"""
    <section id="agenda" class="bg-white py-20">
      <div class="mx-auto max-w-container px-4">
        <.section_heading
          title="Watch the Campaign"
          accent="Campaign"
          description="Catch the latest moments from the trail — tap any clip to watch on YouTube and social media."
        />
      </div>

      <.video_carousel videos={@videos} />

      <div class="mx-auto max-w-container px-4">
        <div class="mt-16" id="#events">
          <.section_heading
            title="Upcoming"
            accent="Events"
            description="Follow the latest news and updates from the campaign trail ."
          />

          <div class="grid grid-cols-1 gap-7 md:grid-cols-3">
            <.event_card :for={event <- @events} event={event} />
          </div>
        </div>
      </div>
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
      <.link navigate={~p"/blog/#{@item.slug}"} class="block overflow-hidden">
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

  attr :item, :map, required: true

  defp shop_card(assigns) do
    ~H"""
    <div class="group">
      <a href="#shop" class="block overflow-hidden rounded-[5px]">
        <img
          src={@item.image}
          alt={@item.name}
          loading="lazy"
          class="h-[420px] w-full object-cover object-[center_30%] transition duration-500 group-hover:scale-105"
        />
      </a>

      <div class="mt-5 text-center">
        <a href="#shop">
          <h6 class="font-head text-lg uppercase text-blueink transition hover:text-crimson">
            {@item.name}
          </h6>
        </a>
        <div class="mt-1 font-head text-lg font-medium text-crimson">{@item.price}</div>
      </div>
    </div>
    """
  end

  attr :event, :map, required: true

  defp event_card(assigns) do
    ~H"""
    <article class="group flex items-stretch gap-4">
      <div class="flex shrink-0 flex-col items-center justify-center rounded-[5px] bg-blueink px-4 py-3 text-white">
        <div class="font-head text-3xl leading-none">{@event.day}</div>
        <div class="font-head text-sm uppercase tracking-wide">{@event.month}</div>
      </div>

      <div class="flex-1">
        <a href="#agenda">
          <h4 class="mt-0 font-head text-2xl uppercase tracking-[.5px] text-blueink transition hover:text-crimson">
            {@event.title}
          </h4>
        </a>
        <p class="mt-1 text-base leading-7 text-grayink">
          Organizing for Action: We're the people who don't just support
        </p>
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
    <a
      href={@video.href}
      target="_blank"
      rel="noopener"
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
    </a>
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
    <a href="#gallery" class={["group relative block overflow-hidden", @image.class]}>
      <img
        src={@image.image}
        alt="Campaign gallery"
        loading="lazy"
        class={[
          @image.height_class,
          "w-full object-cover object-[center_30%] transition duration-500 group-hover:scale-105"
        ]}
      />
      <span class="absolute inset-0 flex items-center justify-center bg-blueink/0 text-4xl font-light text-white opacity-0 transition group-hover:bg-blueink/60 group-hover:opacity-100 sm:text-5xl">
        +
      </span>
    </a>
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
end
