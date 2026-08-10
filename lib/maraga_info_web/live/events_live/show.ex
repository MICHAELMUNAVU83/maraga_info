defmodule MaragaInfoWeb.EventsLive.Show do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfoWeb.Seo

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    case Content.get_published_event(id) do
      nil ->
        {:noreply, push_navigate(socket, to: ~p"/events")}

      event ->
        {:noreply,
         assign(socket,
           event: event,
           page_title: "#{event.title} | #{Seo.site_name()}",
           page_description: event.description,
           page_image: event.image_url,
           canonical_url: Seo.site_url() <> "/events/#{event.id}"
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white">
      <.site_header base_path="/" />

      <section class="bg-ghost py-12">
        <div class="mx-auto max-w-[860px] px-4">
          <.link
            navigate={~p"/events"}
            class="inline-flex items-center gap-2 font-head text-xs uppercase tracking-[0.18em] text-grayink transition hover:text-crimson"
          >
            <.icon name="hero-arrow-left-mini" class="h-4 w-4" /> Campaign Calendar
          </.link>

          <h1 class="mt-6 font-head text-3xl uppercase tracking-[0.04em] text-blueink md:text-4xl">
            {@event.title}
          </h1>

          <div class="mt-4 flex flex-wrap items-center gap-x-6 gap-y-2 text-sm text-grayink">
            <p class="flex items-center gap-1.5">
              <.icon name="hero-clock-mini" class="h-4 w-4 text-crimson" />
              {format_when(@event)}
            </p>
            <p :if={present?(@event.location)} class="flex items-center gap-1.5">
              <.icon name="hero-map-pin-mini" class="h-4 w-4 text-crimson" />
              {@event.location}
            </p>
          </div>

          <img
            :if={present?(@event.image_url)}
            src={@event.image_url}
            alt={@event.title}
            class="mt-8 w-full rounded-[8px] object-cover shadow-[0_15px_40px_rgba(15,30,80,0.12)]"
          />

          <p
            :if={present?(@event.description)}
            class="mt-8 whitespace-pre-line text-base leading-7 text-grayink"
          >
            {@event.description}
          </p>

          <div class="mt-10">
            <.share_bar
              url={@canonical_url}
              title={@event.title}
              label="Share this event"
              id="event-copy-link"
            />
          </div>
        </div>
      </section>

      <.site_footer base_path={~p"/"} />
    </div>
    """
  end

  defp format_when(%{all_day: true} = event),
    do: Calendar.strftime(event.starts_at, "%A, %B %-d, %Y")

  defp format_when(event),
    do: Calendar.strftime(event.starts_at, "%A, %B %-d, %Y · %-I:%M %p")

  defp present?(nil), do: false
  defp present?(value) when is_binary(value), do: String.trim(value) != ""
end
