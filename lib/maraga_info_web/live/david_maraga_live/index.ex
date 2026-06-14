defmodule MaragaInfoWeb.DavidMaragaLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfoWeb.Seo

  @milestones [
    %{
      title: "Annulled the 2017 Presidential Election",
      body:
        "The first such ruling in Africa, demonstrating unmatched judicial courage and independence."
    },
    %{
      title: "Defended Constitutional Accountability",
      body:
        "Advised the President to dissolve Parliament over its failure to meet the two-thirds gender rule, setting a powerful precedent for legal fidelity."
    },
    %{
      title: "Modernised the Judiciary",
      body:
        "Introduced digital case e-filing, the Judiciary Committee on Elections, and cleared significant case backlogs."
    },
    %{
      title: "Expanded Access to Justice",
      body:
        "Strengthened access through mobile courts in remote areas and pushed for internal anti-corruption systems to increase transparency and accountability."
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "David Maraga | #{Seo.site_name()}",
       page_description:
         "The life of David Kenani Maraga — Kenya's 14th Chief Justice — a man of integrity for a time that demands character.",
       canonical_url: Seo.absolute_url("/david-maraga"),
       milestones: @milestones
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white">
      <.site_header base_path="/" />

      <section
        class="relative overflow-hidden bg-cover"
        style="background-position: center 25%; background-image: url('/images/justin-lagat-7e16OcueiNs-unsplash.jpg');"
      >
        <div aria-hidden="true" class="absolute inset-0 bg-blueink/80"></div>

        <div class="relative z-10 mx-auto flex w-full max-w-container flex-col items-center px-4 py-28 text-center lg:px-6 lg:py-36">
          <h3 class="font-serifi text-2xl italic text-white">Life of the Former Chief Justice</h3>
          <h1 class="mt-3 font-head text-[40px] font-semibold uppercase leading-[1.05] tracking-[2px] text-white md:text-[64px]">
            David Kenani <span class="text-crimson">Maraga</span>
          </h1>
          <p class="mt-6 max-w-3xl font-serifi text-lg italic leading-8 text-white/85 sm:text-xl">
            "A man of integrity for a time that demands character."
          </p>
        </div>
      </section>

      <section class="bg-white py-20 lg:py-28">
        <div class="mx-auto grid max-w-container grid-cols-1 items-start gap-12 px-4 lg:grid-cols-[0.85fr_1.15fr] lg:gap-16">
          <img
            src="/images/IMG_2028.jpg"
            alt="David Kenani Maraga"
            loading="lazy"
            class="w-full rounded-[8px] object-cover shadow-[0_15px_40px_rgba(15,30,80,0.12)]"
          />

          <div class="flex flex-col gap-6">
            <div>
              <h3 class="font-serifi text-2xl italic text-crimson">Early Life & Education</h3>
              <h2 class="mt-2 font-head text-3xl uppercase tracking-[.5px] text-blueink">
                A Foundation in Law
              </h2>
            </div>
            <p class="text-base leading-7 text-grayink">
              David Kenani Maraga was born 12 January 1951 in Nyamira County, Kenya. He was the 14th
              Chief Justice and President of the Supreme Court of Kenya from October 2016 until his
              retirement in January 2021.
            </p>
            <p class="text-base leading-7 text-grayink">
              He achieved his Bachelor of Laws degree from the University of Nairobi; holds a
              post-graduate diploma awarded by the Kenya School of Law; and obtained a Master of Laws
              from the University of Nairobi.
            </p>
            <p class="text-base leading-7 text-grayink">
              David Maraga is celebrated for a trailblazing judicial career marked by landmark
              achievements in integrity, reform, and constitutionalism. Under his leadership, the
              judiciary introduced major reforms, and he personally authored over 1,250 Court of
              Appeal judgments.
            </p>
          </div>
        </div>
      </section>

      <section
        class="relative overflow-hidden bg-white py-20 lg:py-28"
        style="background-image: radial-gradient(#dfe3ee 1.6px, transparent 1.7px); background-size: 24px 24px; background-position: center;"
      >
        <div class="mx-auto max-w-container px-4">
          <div class="mx-auto max-w-2xl text-center">
            <h3 class="font-serifi text-2xl italic text-crimson">A Legacy of Courage</h3>
            <h2 class="mt-3 font-head text-[34px] font-semibold uppercase leading-[1.1] tracking-[1px] text-blueink md:text-[44px]">
              Landmark Achievements
            </h2>
          </div>

          <div class="mt-14 grid grid-cols-1 gap-7 md:grid-cols-2">
            <.milestone_card :for={milestone <- @milestones} milestone={milestone} />
          </div>
        </div>
      </section>

      <section class="bg-blueink py-20 lg:py-24">
        <div class="mx-auto max-w-container px-4 text-center">
          <h3 class="font-serifi text-2xl italic text-crimson">Beyond the Bench</h3>
          <h2 class="mt-3 font-head text-[30px] font-semibold uppercase leading-[1.1] tracking-[1px] text-white md:text-[40px]">
            A Continuing Commitment
          </h2>
          <p class="mx-auto mt-6 max-w-3xl text-base leading-8 text-white/80 sm:text-lg">
            Post-retirement, Maraga has remained active in civic life, mentoring youth, promoting
            ethical leadership, and speaking on democracy and governance. His unwavering commitment to
            the rule of law, personal integrity, and empathetic leadership has cemented his legacy as
            one of Kenya's most principled and effective judicial reformers.
          </p>
        </div>
      </section>

      <.site_footer base_path={~p"/"} />
    </div>
    """
  end

  attr :milestone, :map, required: true

  defp milestone_card(assigns) do
    ~H"""
    <article class="flex flex-col rounded-[5px] bg-white p-8 shadow-[0_15px_40px_rgba(15,30,80,0.08)]">
      <h3 class="font-head text-2xl uppercase tracking-[.5px] text-blueink">
        {@milestone.title}
      </h3>
      <div class="my-5 h-px w-full bg-[#e6e6e6]"></div>
      <p class="text-base leading-7 text-grayink">
        {@milestone.body}
      </p>
    </article>
    """
  end
end
