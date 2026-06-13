defmodule MaragaInfoWeb.HomeLive.Index do
  use MaragaInfoWeb, :live_view

  @social_links [
    %{name: "x", href: "https://x.com/dkmaraga", label: "X"},
    %{name: "instagram", href: "https://www.instagram.com/maraga2027", label: "Instagram"},
    %{name: "youtube", href: "https://www.youtube.com/@dkmaraga", label: "YouTube"}
  ]
  @news_items [
    %{
      date: "Aug 30, 2022",
      category: "Political",
      title: "How can we improve immigration policy?",
      image: "https://images.unsplash.com/photo-1529107386315-e1a2ed48a620?w=1080&q=80"
    },
    %{
      date: "Sep 20, 2022",
      category: "My passion",
      title: "We're the people who don't just support progressive change",
      image: "https://images.unsplash.com/photo-1485081669829-bacb8c7bb1f3?w=1080&q=80"
    },
    %{
      date: "Sep 16, 2022",
      category: "My passion",
      title: "Security for the middle class",
      image: "https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=1080&q=80"
    },
    %{
      date: "Sep 5, 2022",
      category: "My passion",
      title: "Politics is why we can't have nice things. Like the internet",
      image: "https://images.unsplash.com/photo-1591189863430-ab87e120f312?w=1080&q=80"
    }
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

  @events [
    %{day: "08", month: "Jun", title: "Nairobi National Park Protest – Maraga Arrested"},
    %{day: "25", month: "May", title: "Ukombozi Campaign Launch – Lodwar, Turkana"},
    %{day: "05", month: "Feb", title: "Ukatiba Caravan – Lamu County Voter Drive"}
  ]

  @gallery_images [
    %{
      image: "/images/gallery/1.jpg",
      class: "col-span-2 row-span-2",
      height_class: "h-64 sm:h-full"
    },
    %{
      image: "/images/gallery/2.jpg",
      class: "",
      height_class: "h-44 sm:h-full"
    },
    %{
      image: "/images/gallery/3.jpg",
      class: "",
      height_class: "h-44 sm:h-full"
    },
    %{
      image: "/images/gallery/4.jpg",
      class: "",
      height_class: "h-44 sm:h-full"
    },
    %{
      image: "/images/gallery/5.jpg",
      class: "object-center",
      height_class: "h-44  sm:h-full"
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Home",
       social_links: @social_links,
       news_items: @news_items,
       stats: @stats,
       shop_items: @shop_items,
       events: @events,
       gallery_images: @gallery_images
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="top" class="min-h-screen bg-white">
      <.site_header social_links={@social_links} />
      <.hero_section />
      <.donate_section />
      <.mission_section />
      <.news_section news_items={@news_items} />
      <.newsletter_section stats={@stats} />
      <%!-- <.shop_section shop_items={@shop_items} /> --%>
      <.agenda_section events={@events} />
      <.gallery_section gallery_images={@gallery_images} />
      <.site_footer id="footer" />
    </div>
    """
  end

  attr :social_links, :list, required: true

  defp site_header(assigns) do
    ~H"""
    <header class="relative z-30 w-full bg-blueink">
      <input id="nav-toggle" type="checkbox" class="peer hidden" />

      <div class="relative mx-auto flex w-full max-w-container items-center justify-between gap-4 px-4 py-3 lg:px-6">
        <nav class="hidden items-center gap-6 lg:flex">
          <div class="mr-2 flex items-center gap-3">
            <.social_link
              :for={link <- @social_links}
              link={link}
              class="text-white hover:text-crimson"
            />
          </div>
          <a
            href="#top"
            class="font-head text-[15px] font-medium uppercase tracking-wide text-crimson"
          >
            Home
          </a>

          <div class="group relative">
            <button
              type="button"
              class="flex items-center gap-1 font-head text-[15px] font-medium uppercase tracking-wide text-white transition group-hover:text-crimson"
            >
              Pages
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
            <div class="absolute left-0 top-full z-50 hidden w-[200px] grid-cols-1 gap-x-10 gap-y-1 rounded-md bg-white p-6 shadow-2xl group-hover:grid group-focus-within:grid">
              <a href="#" class="text-[15px] text-ink transition hover:text-crimson">Home</a>

              <a href="#mission" class="text-[15px] text-ink transition hover:text-crimson">
                About Us
              </a>
            </div>
          </div>

          <a
            href="#mission"
            class="font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
          >
            About Us
          </a>
        </nav>

        <a href="#top" class="flex shrink-0 items-center gap-2 lg:hidden">
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
              class="hidden h-12 w-auto shrink-0 lg:block"
            />
          </span>
        </a>

        <a
          href="#top"
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
            <a
              href="#agenda"
              class="font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
            >
              Our Agenda
            </a>
            <a
              href="#news"
              class="font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
            >
              Blogs
            </a>
          </nav>
        </div>
      </div>

      <nav class="hidden flex-col gap-1 bg-blueink px-6 pb-6 pt-2 shadow-xl peer-checked:flex lg:!hidden">
        <a
          href="#top"
          class="py-1 font-head text-[15px] font-medium uppercase tracking-wide text-crimson"
        >
          Home
        </a>
        <a
          href="#gallery"
          class="py-1 font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
        >
          Pages
        </a>
        <a
          href="#mission"
          class="py-1 font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
        >
          About Us
        </a>
        <a
          href="#agenda"
          class="py-1 font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
        >
          Our Agenda
        </a>
        <a
          href="#news"
          class="py-1 font-head text-[15px] font-medium uppercase tracking-wide text-white transition hover:text-crimson"
        >
          Blog
        </a>
      </nav>
    </header>
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
          <h3 class="font-serifi text-2xl italic text-white">Presidential Candidate 2027</h3>
          <h1 class="mt-3 font-head text-[44px] font-semibold uppercase leading-[1.05] tracking-[3px] text-white md:text-[72px] lg:text-[90px]">
            Jiandikishe <br /> Kupiga Kura
          </h1>

          <div class="mt-12 flex flex-col items-stretch gap-4 sm:flex-row sm:items-center sm:justify-center">
            <a
              href="#mission"
              class="inline-flex min-w-[190px] items-center justify-center rounded-full bg-white px-8 py-3.5 font-head text-[13px] font-bold uppercase tracking-[0.2em] text-blueink transition duration-300 hover:bg-crimson"
            >
              Read More
            </a>
            <a
              href="https://donations.davidmaraga.com/"
              rel="noopener"
              target="_blank"
              class="inline-flex min-w-[190px] items-center justify-center rounded-full border-2 border-white px-8 py-3.5 font-head text-[13px] font-bold uppercase tracking-[0.2em] text-white transition duration-300 hover:bg-white hover:text-blueink"
            >
              Donate
            </a>
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
            <.donation_chip amount="KES 500" />
            <.donation_chip amount="KES 1000" />
            <.donation_chip amount="KES 2000" />
            <.donation_chip amount="KES 5000" />

            <input
              type="text"
              placeholder="More"
              class="w-24 rounded-[5px] border border-[#e6e6e6] bg-white px-4 py-3 text-ink outline-none focus:border-blueink"
            />
          </div>

          <a
            type="button"
            href="https://donations.davidmaraga.com/"
            rel="noopener"
            target="_blank"
            class="rounded-[5px] border-2 border-blueink bg-blueink px-[30px] py-4 font-semibold text-white transition hover:bg-transparent hover:text-blueink"
          >
            Donate Now
          </a>
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
            class="h-[360px] w-full rounded-[5px] object-cover shadow-2xl sm:h-[620px] lg:h-[820px]"
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

        <div class="grid grid-cols-1 gap-7  md:grid-cols-2">
          <.news_card :for={item <- @news_items} item={item} />
        </div>

        <div class="mt-12 flex items-center justify-center gap-2">
          <span class="h-3 w-3 rounded-full bg-blueink"></span>
          <span class="h-3 w-3 rounded-full bg-[#c8c8c8]"></span>
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

          <p class="mt-14 text-center font-head text-sm uppercase tracking-[0.45em] text-white/60 sm:text-base">
            Tawala Maraga · Tawala Kenya · 2027
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

  defp agenda_section(assigns) do
    ~H"""
    <section id="agenda" class="bg-white py-20">
      <div class="mx-auto max-w-container px-4">
        <a
          id="agenda-video"
          phx-hook="RevealOnScroll"
          href="https://www.youtube.com/watch?v=o0KmjcGd6jw"
          target="_blank"
          rel="noopener"
          class="reveal-on-scroll group relative block h-[360px] overflow-hidden rounded-[10px] shadow-[0_10px_30px_#0006] sm:h-[480px] lg:h-[600px]"
          style="background-image: url('/images/maxresdefault.jpg'); background-size: cover; background-position: center;"
        >
          <div class="absolute inset-0 bg-black/50 transition group-hover:bg-black/40"></div>
          <div class="absolute inset-0 flex items-center justify-center">
            <span class="flex h-24 w-24 items-center justify-center rounded-full bg-white shadow-lg transition group-hover:scale-110">
              <svg
                class="ml-1 h-9 w-9 text-crimson"
                viewBox="0 0 24 24"
                fill="currentColor"
                aria-hidden="true"
              >
                <polygon points="6 4 20 12 6 20 6 4" />
              </svg>
            </span>
          </div>
        </a>

        <div class="mt-16">
          <.section_heading
            title="Ukombozi"
            accent="Rallies"
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
      <a href="#news" class="block overflow-hidden">
        <img
          src={@item.image}
          alt={@item.title}
          loading="lazy"
          class="h-[300px] w-full object-cover transition duration-500 group-hover:scale-105"
        />
      </a>

      <div class="flex flex-1 flex-col p-7">
        <div class="flex items-center gap-2 text-xs">
          <span class="font-bold uppercase tracking-[2px] text-crimson">{@item.date}</span>
          <span class="text-grayink">|</span>
          <a
            href="#news"
            class="font-bold uppercase tracking-[1px] text-grayink transition hover:text-crimson"
          >
            {@item.category}
          </a>
        </div>
        <a href="#news">
          <h4 class="mt-3 font-head text-2xl uppercase tracking-[.5px] text-blueink transition hover:text-crimson">
            {@item.title}
          </h4>
        </a>
        <div class="my-5 h-px w-full bg-[#e6e6e6]"></div>
        <p class="mt-0 text-base leading-7 text-grayink">
          The Brady Bunch the Brady Bunch that is the way we all go on got a dream...
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
          class="h-[420px] w-full object-cover transition duration-500 group-hover:scale-105"
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

      <div class="font-head text-2xl tracking-[0.3em] text-[#d0b216]">★★★</div>
      <div class="mt-5 font-head text-5xl font-bold leading-none text-white sm:text-6xl">
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
          "w-full object-cover object-top transition duration-500 group-hover:scale-105"
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

  attr :link, :map, required: true
  attr :class, :string, default: ""

  defp social_link(assigns) do
    ~H"""
    <a
      href={@link.href}
      target="_blank"
      rel="noopener"
      aria-label={@link.label}
      class={["transition", @class]}
    >
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
      <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z" />
      <line x1="17.5" y1="6.5" x2="17.51" y2="6.5" />
    </svg>
    """
  end

  defp social_icon(%{name: "youtube"} = assigns) do
    ~H"""
    <svg class="h-[18px] w-[18px]" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M23.5 6.2a3 3 0 0 0-2.1-2.1C19.5 3.5 12 3.5 12 3.5s-7.5 0-9.4.6A3 3 0 0 0 .5 6.2 31 31 0 0 0 0 12a31 31 0 0 0 .5 5.8 3 3 0 0 0 2.1 2.1c1.9.6 9.4.6 9.4.6s7.5 0 9.4-.6a3 3 0 0 0 2.1-2.1A31 31 0 0 0 24 12a31 31 0 0 0-.5-5.8zM9.6 15.6V8.4l6.2 3.6z" />
    </svg>
    """
  end

  attr :class, :string, default: nil

  defp star(assigns) do
    ~H"""
    <svg class={@class} viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M12 2l2.9 6.3 6.9.7-5.1 4.6 1.4 6.8L12 18.6 5 21l1.4-6.8L1.3 9.6l6.9-.7z" />
    </svg>
    """
  end
end
