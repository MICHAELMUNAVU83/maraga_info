defmodule MaragaInfoWeb.UgmPartyLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfoWeb.Seo

  @party_url "https://ugmparty.co.ke"

  @core_values [
    "Respect for constitutionalism and the rule of law.",
    "Respect for individual and people's rights and freedoms.",
    "Democratic governance and people's participation.",
    "Freedom with responsibility.",
    "Empowerment of the marginalized groups and sections of society.",
    "Positive and mutually beneficial international relations."
  ]

  @objectives [
    "To eradicate unfairly engineered social inequalities.",
    "To encourage and promote coalition among parties pursuing similar objectives in Kenya.",
    "To establish a transparent and accountable government."
  ]

  @principles [
    "Grassroots democracy",
    "Social justice and equal opportunity",
    "Ecological wisdom",
    "Community based economics",
    "Non-violence",
    "Feminism",
    "Respect for diversity",
    "Personal and global responsibility",
    "Decentralization",
    "Economic and development sustainability"
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "UGM Party | #{Seo.site_name()}",
       page_description:
         "The United Green Movement (UGM) Party's vision, mission, core values, objectives and guiding principles for a united, peaceful and prosperous Kenya.",
       canonical_url: Seo.absolute_url("/ugm-party"),
       party_url: @party_url,
       core_values: @core_values,
       objectives: @objectives,
       principles: @principles
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white">
      <.site_header base_path="/" />

      <section
        class="relative overflow-hidden bg-cover"
        style="background-position: center 30%; background-image: url('/images/maraga-town.jpg');"
      >
        <div aria-hidden="true" class="absolute inset-0 bg-blueink/80"></div>

        <div class="relative z-10 mx-auto flex w-full max-w-container flex-col items-center px-4 py-28 text-center lg:px-6 lg:py-36">
          <h3 class="font-serifi text-2xl italic text-white">About Us</h3>
          <h1 class="mt-3 font-head text-[40px] font-semibold uppercase leading-[1.05] tracking-[2px] text-white md:text-[64px]">
            United <span class="text-crimson">Green Movement</span>
          </h1>
          <p class="mt-6 max-w-3xl text-base leading-7 text-white/85 sm:text-lg">
            The political home of David Maraga's mission — a united, peaceful and prosperous
            nation where every citizen lives in dignity and in harmony with their environment.
          </p>
          <a
            href={@party_url}
            target="_blank"
            rel="noopener noreferrer"
            class="mt-8 inline-flex items-center gap-2 rounded-[4px] bg-crimson px-7 py-3 font-head text-sm font-semibold uppercase tracking-[2px] text-blueink transition hover:bg-white"
          >
            Visit ugmparty.co.ke
          </a>
        </div>
      </section>

      <section class="bg-white py-20 lg:py-28">
        <div class="mx-auto grid max-w-container grid-cols-1 items-center gap-12 px-4 lg:grid-cols-2 lg:gap-16">
          <img
            src="/images/UGM LOGO NEW copy (2).png"
            alt="United Green Movement Party"
            loading="lazy"
            class="w-full rounded-[8px] object-cover shadow-[0_15px_40px_rgba(15,30,80,0.12)]"
          />

          <div class="flex flex-col gap-10">
            <div>
              <h2 class="font-head text-3xl uppercase tracking-[.5px] text-blueink">
                Vision
              </h2>
              <p class="mt-4 text-base leading-7 text-grayink">
                United Green Movement Party's vision shall be to establish a united, peaceful, &
                prosperous nation, in which all citizens enjoy social, economic and democratic
                rights, living in dignity and in harmony with their environment.
              </p>
            </div>

            <div>
              <h2 class="font-head text-3xl uppercase tracking-[.5px] text-blueink">
                Mission Statement
              </h2>
              <p class="mt-4 text-base leading-7 text-grayink">
                To build a state and society in which all Kenyans will have a better life and live
                in harmony with the environment.
              </p>
            </div>

            <a
              href={@party_url}
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex w-fit items-center gap-2 font-head text-sm font-semibold uppercase tracking-[2px] text-crimson transition hover:text-blueink"
            >
              Read more <span aria-hidden="true">→</span>
            </a>
          </div>
        </div>
      </section>

      <section
        class="relative overflow-hidden bg-white py-20 lg:py-28"
        style="background-image: radial-gradient(#dfe3ee 1.6px, transparent 1.7px); background-size: 24px 24px; background-position: center;"
      >
        <div class="mx-auto max-w-container px-4">
          <div class="mx-auto max-w-2xl text-center">
            <h3 class="font-serifi text-2xl italic text-crimson">What We Stand For</h3>
            <h2 class="mt-3 font-head text-[34px] font-semibold uppercase leading-[1.1] tracking-[1px] text-blueink md:text-[44px]">
              Our Core Values & Objectives
            </h2>
          </div>

          <div class="mt-14 grid grid-cols-1 gap-7 md:grid-cols-2">
            <.value_card title="Core Values" items={@core_values} />
            <.value_card title="Objectives" items={@objectives} />
          </div>

          <div class="mt-7">
            <.value_card title="Principles" items={@principles} columns={true} />
          </div>

          <div class="mt-12 text-center">
            <a
              href={@party_url}
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-2 rounded-[4px] bg-blueink px-7 py-3 font-head text-sm font-semibold uppercase tracking-[2px] text-white transition hover:bg-crimson hover:text-blueink"
            >
              Read more on ugmparty.co.ke <span aria-hidden="true">→</span>
            </a>
          </div>
        </div>
      </section>

      <.site_footer base_path={~p"/"} />
    </div>
    """
  end

  attr :title, :string, required: true
  attr :items, :list, required: true
  attr :columns, :boolean, default: false

  defp value_card(assigns) do
    ~H"""
    <article class="flex flex-col rounded-[5px] bg-white p-8 shadow-[0_15px_40px_rgba(15,30,80,0.08)]">
      <h3 class="font-head text-2xl uppercase tracking-[.5px] text-blueink">
        {@title}
      </h3>
      <div class="my-5 h-px w-full bg-[#e6e6e6]"></div>
      <ul class={[
        "space-y-3 text-base leading-7 text-grayink",
        @columns && "sm:columns-2 sm:gap-x-10 sm:space-y-0"
      ]}>
        <li :for={item <- @items} class="flex items-start gap-3 break-inside-avoid sm:mb-3">
          <span aria-hidden="true" class="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-crimson"></span>
          <span>{item}</span>
        </li>
      </ul>
    </article>
    """
  end
end
