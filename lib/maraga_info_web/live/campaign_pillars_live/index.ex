defmodule MaragaInfoWeb.CampaignPillarsLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfoWeb.Seo

  @pillars [
    %{
      number: "01",
      title: "Youth Empowerment & Employment",
      description:
        "Harnessing Kenya's large youth population (70% of ~52 million) as a productive force to address societal challenges."
    },
    %{
      number: "02",
      title: "Environment & Sustainability",
      description:
        "Protecting the environment as a shared heritage, ensuring every citizen's right to a clean and healthy environment."
    },
    %{
      number: "03",
      title: "Economic Freedom",
      description:
        "Addressing obstacles to economic growth including judicial ineffectiveness, poor government integrity, and fiscal health challenges."
    },
    %{
      number: "04",
      title: "Rule of Law & Democracy",
      description:
        "Upholding the supremacy of the law as the foundation of a free and democratic society."
    },
    %{
      number: "05",
      title: "Social Justice & Equality",
      description:
        "Preserving human dignity, promoting universal human rights, and ensuring full development of every citizen's potential."
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Campaign Pillars | #{Seo.site_name()}",
       page_description:
         "The five core pillars anchoring David Maraga's mission for a Kenya where every citizen thrives — economically, socially, and environmentally.",
       canonical_url: Seo.absolute_url("/campaign-pillars"),
       pillars: @pillars
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white">
      <.site_header base_path="/" />

      <section
        class="relative overflow-hidden bg-cover"
        style="background-position: center 10%; background-image: url('/images/IMG_2028.jpg');"
      >
        <div aria-hidden="true" class="absolute inset-0 bg-blueink/80"></div>

        <div class="relative z-10 mx-auto flex w-full max-w-container flex-col items-center px-4 py-28 text-center lg:px-6 lg:py-36">
          <h3 class="font-serifi text-2xl italic text-white">Our Agenda</h3>
          <h1 class="mt-3 font-head text-[40px] font-semibold uppercase leading-[1.05] tracking-[2px] text-white md:text-[64px]">
            Campaign <span class="text-crimson">Pillars</span>
          </h1>
          <p class="mt-6 max-w-3xl text-base leading-7 text-white/85 sm:text-lg">
            We're building a Kenya where every citizen thrives — economically, socially, and
            environmentally. Our mission is anchored in five core pillars.
          </p>
        </div>
      </section>

      <section
        class="relative overflow-hidden bg-white py-20 lg:py-28"
        style="background-image: radial-gradient(#dfe3ee 1.6px, transparent 1.7px); background-size: 24px 24px; background-position: center;"
      >
        <div class="mx-auto max-w-container px-4">
          <div class="grid grid-cols-1 gap-7 md:grid-cols-2">
            <.pillar_card :for={pillar <- @pillars} pillar={pillar} />
          </div>
        </div>
      </section>

      <.site_footer base_path={~p"/"} />
    </div>
    """
  end

  attr :pillar, :map, required: true

  defp pillar_card(assigns) do
    ~H"""
    <article class="group flex flex-col rounded-[5px] bg-white p-8 shadow-[0_15px_40px_rgba(15,30,80,0.08)] transition hover:shadow-[0_20px_55px_rgba(15,30,80,0.14)]">
      <div class="flex items-center gap-4">
        <span class="font-head text-5xl font-semibold leading-none text-crimson">
          {@pillar.number}
        </span>
        <span class="h-px flex-1 bg-[#e6e6e6]"></span>
      </div>

      <h2 class="mt-6 font-head text-2xl uppercase tracking-[.5px] text-blueink transition group-hover:text-crimson">
        {@pillar.title}
      </h2>

      <p class="mt-4 text-base leading-7 text-grayink">
        {@pillar.description}
      </p>
    </article>
    """
  end
end
