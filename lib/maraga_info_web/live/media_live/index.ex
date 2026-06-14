defmodule MaragaInfoWeb.MediaLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfoWeb.Seo

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Media Gallery | #{Seo.site_name()}")
     |> assign(
       :page_description,
       "Photography from the David Maraga campaign trail across Kenya."
     )
     |> assign(:canonical_url, Seo.site_url() <> "/media")
     |> assign(:categories, Content.list_published_media_categories())
     |> assign(:active_category, "all")
     |> assign(:selected, nil)
     |> load_items("all")}
  end

  @impl true
  def handle_event("filter", %{"category" => category}, socket) do
    {:noreply,
     socket
     |> assign(:active_category, category)
     |> load_items(category)}
  end

  def handle_event("open", %{"id" => id}, socket) do
    selected = Enum.find(socket.assigns.items, &(to_string(&1.id) == id))
    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, :selected, nil)}
  end

  defp load_items(socket, category) do
    assign(socket, :items, Content.list_published_media_items(category: category))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white">
      <.site_header base_path="/" />

      <section
        class="relative overflow-hidden bg-cover"
        style="background-position: center 35%; background-image: url('/images/justin-lagat-7e16OcueiNs-unsplash.jpg');"
      >
        <div class="absolute inset-0 bg-blueink/70"></div>
        <div class="relative z-10 mx-auto flex min-h-[42vh] w-full max-w-container flex-col items-center justify-center px-4 py-24 text-center lg:px-6">
          <h3 class="font-serifi text-2xl italic text-white">David Maraga · Kenya 2027</h3>
          <h1 class="mt-3 font-head text-4xl font-semibold uppercase tracking-[3px] text-white md:text-6xl lg:text-7xl">
            Media Gallery
          </h1>
        </div>
      </section>

      <section class="bg-white py-16">
        <div class="mx-auto max-w-container px-4">
          <div class="mb-10 flex flex-wrap items-center justify-between gap-4">
            <h2 class="font-head text-2xl uppercase tracking-[0.08em] text-blueink">
              All <span class="text-crimson">Media</span>
            </h2>

            <div class="flex flex-wrap items-center gap-5">
              <.filter_tab label="All Projects" value="all" active={@active_category} />
              <.filter_tab
                :for={category <- @categories}
                label={category}
                value={category}
                active={@active_category}
              />
            </div>
          </div>

          <div :if={@items == []} class="rounded-[8px] bg-ghost px-8 py-16 text-center">
            <h3 class="font-head text-2xl uppercase tracking-[0.08em] text-blueink">
              No media here yet
            </h3>
            <p class="mx-auto mt-3 max-w-xl text-base leading-7 text-grayink">
              Images added in the admin media library will appear in this gallery automatically.
            </p>
          </div>

          <div :if={@items != []} class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            <.media_card :for={item <- @items} item={item} />
          </div>
        </div>
      </section>

      <.site_footer base_path={~p"/"} />

      <.modal :if={@selected} id="media-lightbox" show on_cancel={JS.push("close")}>
        <img
          src={@selected.image_url}
          alt={@selected.title}
          class="max-h-[70vh] w-full rounded-[6px] object-contain"
        />
        <div class="mt-5">
          <span class="font-head text-xs uppercase tracking-[0.18em] text-crimson">
            {@selected.category}
          </span>
          <h3 class="mt-1 font-head text-2xl uppercase tracking-[0.04em] text-blueink">
            {@selected.title}
          </h3>
          <p :if={present?(@selected.description)} class="mt-3 text-base leading-7 text-grayink">
            {@selected.description}
          </p>
        </div>
      </.modal>
    </div>
    """
  end

  attr :item, :map, required: true

  defp media_card(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="open"
      phx-value-id={@item.id}
      class="group relative block overflow-hidden rounded-[6px] text-left shadow-[0_15px_40px_rgba(15,30,80,0.08)]"
    >
      <img
        src={@item.image_url}
        alt={@item.title}
        loading="lazy"
        class="h-72 w-full object-cover object-[center_30%] transition duration-500 group-hover:scale-105"
      />
      <span class="absolute inset-0 flex flex-col items-center justify-center gap-2 bg-blueink/0 px-4 text-center opacity-0 transition group-hover:bg-blueink/65 group-hover:opacity-100">
        <span class="font-head text-xs uppercase tracking-[0.2em] text-crimson">
          {@item.category}
        </span>
        <span class="font-head text-xl uppercase tracking-[0.04em] text-white">
          {@item.title}
        </span>
      </span>
    </button>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :active, :string, required: true

  defp filter_tab(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="filter"
      phx-value-category={@value}
      class={[
        "font-head text-sm font-semibold uppercase tracking-[0.12em] transition",
        @active == @value && "text-crimson",
        @active != @value && "text-blueink hover:text-crimson"
      ]}
    >
      {@label}
    </button>
    """
  end

  defp present?(nil), do: false
  defp present?(value) when is_binary(value), do: String.trim(value) != ""
end
