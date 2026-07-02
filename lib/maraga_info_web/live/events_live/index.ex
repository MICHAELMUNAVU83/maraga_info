defmodule MaragaInfoWeb.EventsLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfoWeb.Seo

  @weekday_labels ~w(Mon Tue Wed Thu Fri Sat Sun)

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Events Calendar | #{Seo.site_name()}")
     |> assign(
       :page_description,
       "Browse upcoming rallies, town halls and campaign events on the David Maraga 2027 calendar."
     )
     |> assign(:canonical_url, Seo.site_url() <> "/events")
     |> assign(:weekday_labels, @weekday_labels)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    month = parse_month(Map.get(params, "month"))
    events = Content.list_published_events()

    {:noreply,
     socket
     |> assign(:month, month)
     |> assign(:events, events)
     |> assign(:events_by_date, group_by_date(events))
     |> assign(:weeks, calendar_weeks(month))
     |> assign(:upcoming, upcoming_events(events))}
  end

  defp parse_month(nil), do: Date.beginning_of_month(Date.utc_today())

  defp parse_month(value) when is_binary(value) do
    case Date.from_iso8601(value <> "-01") do
      {:ok, date} -> Date.beginning_of_month(date)
      _ -> Date.beginning_of_month(Date.utc_today())
    end
  end

  defp month_param(date), do: Calendar.strftime(date, "%Y-%m")

  # Six-week grid (Monday-first) covering the displayed month.
  defp calendar_weeks(month) do
    first = Date.beginning_of_month(month)
    start = Date.add(first, -(Date.day_of_week(first) - 1))

    start
    |> Stream.iterate(&Date.add(&1, 1))
    |> Enum.take(42)
    |> Enum.chunk_every(7)
  end

  defp group_by_date(events) do
    Enum.group_by(events, fn event -> DateTime.to_date(event.starts_at) end)
  end

  defp upcoming_events(events) do
    today = Date.utc_today()

    events
    |> Enum.filter(fn event -> Date.compare(DateTime.to_date(event.starts_at), today) != :lt end)
    |> Enum.take(6)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white">
      <.site_header base_path="/" />

      <section
        class="relative overflow-hidden bg-cover"
        style="background-position: center 35%; background-image: url('/images/maraga-town.jpg');"
      >
        <div class="absolute inset-0 bg-blueink/70"></div>
        <div class="relative z-10 mx-auto flex min-h-[42vh] w-full max-w-container flex-col items-center justify-center px-4 py-24 text-center lg:px-6">
          <h3 class="font-serifi text-2xl italic text-white">David Maraga · Kenya 2027</h3>
          <h1 class="mt-3 font-head text-4xl font-semibold uppercase tracking-[3px] text-white md:text-6xl lg:text-7xl">
            Events Calendar
          </h1>
        </div>
      </section>

      <section class="bg-ghost py-16">
        <div class="mx-auto grid max-w-container gap-10 px-4 lg:grid-cols-[2fr_1fr]">
          <div class="rounded-[8px] bg-white p-5 shadow-[0_15px_40px_rgba(15,30,80,0.08)] sm:p-7">
            <div class="mb-6 flex items-center justify-between">
              <.link
                patch={
                  ~p"/events?#{%{month: month_param(Date.add(Date.beginning_of_month(@month), -1))}}"
                }
                class="flex h-10 w-10 items-center justify-center rounded-full border border-zinc-200 text-blueink transition hover:border-crimson hover:text-crimson"
                aria-label="Previous month"
              >
                <.icon name="hero-chevron-left-mini" class="h-5 w-5" />
              </.link>
              <h2 class="font-head text-2xl uppercase tracking-[0.08em] text-blueink">
                {Calendar.strftime(@month, "%B %Y")}
              </h2>
              <.link
                patch={~p"/events?#{%{month: month_param(Date.add(Date.end_of_month(@month), 1))}}"}
                class="flex h-10 w-10 items-center justify-center rounded-full border border-zinc-200 text-blueink transition hover:border-crimson hover:text-crimson"
                aria-label="Next month"
              >
                <.icon name="hero-chevron-right-mini" class="h-5 w-5" />
              </.link>
            </div>

            <div class="grid grid-cols-7 gap-px border-b border-zinc-100 pb-2 text-center">
              <div
                :for={label <- @weekday_labels}
                class="font-head text-[11px] font-semibold uppercase tracking-[0.14em] text-grayink"
              >
                {label}
              </div>
            </div>

            <div class="mt-2 grid grid-cols-7 gap-1.5">
              <%= for week <- @weeks, day <- week do %>
                <.calendar_day day={day} month={@month} events={Map.get(@events_by_date, day, [])} />
              <% end %>
            </div>
          </div>

          <aside>
            <h2 class="font-head text-2xl uppercase tracking-[0.08em] text-blueink">
              Upcoming <span class="text-crimson">Events</span>
            </h2>

            <div :if={@upcoming == []} class="mt-6 rounded-[8px] bg-white px-6 py-10 text-center">
              <p class="text-base leading-7 text-grayink">
                No upcoming events scheduled yet. Check back soon.
              </p>
            </div>

            <div :if={@upcoming != []} class="mt-6 space-y-4">
              <.upcoming_card :for={event <- @upcoming} event={event} />
            </div>
          </aside>
        </div>
      </section>

      <.site_footer base_path={~p"/"} />
    </div>
    """
  end

  attr :day, Date, required: true
  attr :month, Date, required: true
  attr :events, :list, required: true

  defp calendar_day(assigns) do
    assigns =
      assigns
      |> assign(:in_month, assigns.day.month == assigns.month.month)
      |> assign(:today?, assigns.day == Date.utc_today())

    ~H"""
    <div class={[
      "min-h-[84px] rounded-[6px] border p-1.5 sm:min-h-[104px]",
      @in_month && "border-zinc-100 bg-white",
      !@in_month && "border-transparent bg-zinc-50/60"
    ]}>
      <div class={[
        "flex h-6 w-6 items-center justify-center rounded-full text-xs font-semibold",
        @today? && "bg-crimson text-white",
        !@today? && @in_month && "text-blueink",
        !@today? && !@in_month && "text-zinc-300"
      ]}>
        {@day.day}
      </div>

      <div class="mt-1 space-y-1">
        <div
          :for={event <- @events}
          class="truncate rounded-[3px] bg-blueink/10 px-1.5 py-0.5 text-[11px] font-medium leading-tight text-blueink"
          title={event.title}
        >
          {event.title}
        </div>
      </div>
    </div>
    """
  end

  attr :event, :map, required: true

  defp upcoming_card(assigns) do
    ~H"""
    <article class="overflow-hidden rounded-[8px] bg-white shadow-[0_15px_40px_rgba(15,30,80,0.08)]">
      <img
        :if={present?(@event.image_url)}
        src={@event.image_url}
        alt={@event.title}
        class="h-40 w-full object-cover"
        loading="lazy"
      />
      <div class="flex items-stretch gap-4 p-4">
        <div class="flex shrink-0 flex-col items-center justify-center rounded-[5px] bg-blueink px-4 py-3 text-white">
          <div class="font-head text-3xl leading-none">
            {Calendar.strftime(@event.starts_at, "%d")}
          </div>
          <div class="font-head text-sm uppercase tracking-wide">
            {Calendar.strftime(@event.starts_at, "%b")}
          </div>
        </div>

        <div class="min-w-0 flex-1">
          <h4 class="font-head text-lg uppercase tracking-[.5px] text-blueink">
            {@event.title}
          </h4>
          <p class="mt-1 flex items-center gap-1.5 text-sm text-grayink">
            <.icon name="hero-clock-mini" class="h-4 w-4 text-crimson" />
            {format_when(@event)}
          </p>
          <p
            :if={present?(@event.location)}
            class="mt-0.5 flex items-center gap-1.5 text-sm text-grayink"
          >
            <.icon name="hero-map-pin-mini" class="h-4 w-4 text-crimson" />
            {@event.location}
          </p>
        </div>
      </div>
    </article>
    """
  end

  defp format_when(%{all_day: true} = event), do: Calendar.strftime(event.starts_at, "%A, %B %-d")

  defp format_when(event),
    do: Calendar.strftime(event.starts_at, "%A, %B %-d · %-I:%M %p")

  defp present?(nil), do: false
  defp present?(value) when is_binary(value), do: String.trim(value) != ""
end
