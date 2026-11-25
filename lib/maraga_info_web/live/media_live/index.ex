defmodule MaragaInfoWeb.MediaLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfoWeb.Seo
  alias MaragaInfoWeb.VideoEmbed

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:config, scope_from_path("/media"))
     |> assign(:folders, [])
     |> assign(:folder, nil)
     |> assign(:selected, nil)
     |> assign(:items, [])}
  end

  @impl true
  def handle_params(params, url, socket) do
    path = URI.parse(url).path
    config = scope_from_path(path)

    {:noreply,
     socket
     |> assign(:config, config)
     |> assign(:page_title, "#{config.title} | #{Seo.site_name()}")
     |> assign(:page_description, config.description)
     |> assign(:canonical_url, Seo.site_url() <> config.canonical_path)
     |> assign(:folder, blank_to_nil(params["folder"]))
     |> load_items()}
  end

  @impl true
  def handle_event("open", %{"id" => id}, socket) do
    selected = Enum.find(socket.assigns.items, &(to_string(&1.id) == id))
    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, :selected, nil)}
  end

  defp load_items(socket) do
    all_items = Content.list_published_media_items(media_type: socket.assigns.config.media_type)
    folder = socket.assigns.folder

    items =
      if folder, do: Enum.filter(all_items, &(&1.category == folder)), else: []

    socket
    |> assign(:items, items)
    |> assign(:folders, build_folders(all_items))
  end

  defp build_folders(items) do
    items
    |> Enum.group_by(& &1.category)
    |> Enum.map(fn {name, folder_items} ->
      %{
        name: name,
        count: length(folder_items),
        cover: Enum.find_value(folder_items, & &1.image_url)
      }
    end)
    |> Enum.sort_by(&String.downcase(&1.name || ""))
  end

  defp folder_path(base_path, name), do: base_path <> "?" <> URI.encode_query(folder: name)

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) when is_binary(value) do
    if String.trim(value) == "", do: nil, else: value
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
          <h1 class="font-head text-3xl font-semibold uppercase tracking-[3px] text-white md:text-5xl lg:text-6xl">
            Maraga in the Media
          </h1>
        </div>
      </section>

      <section class="bg-white py-16">
        <div class="mx-auto max-w-container px-4">
          <%= if is_nil(@folder) do %>
            <h2 class="mb-10 font-head text-2xl uppercase tracking-[0.08em] text-blueink">
              {@config.label} <span class="text-crimson">Albums</span>
            </h2>

            <div :if={@folders == []} class="rounded-[8px] bg-ghost px-8 py-16 text-center">
              <h3 class="font-head text-2xl uppercase tracking-[0.08em] text-blueink">
                No {@config.label |> String.downcase()} here yet
              </h3>
              <p class="mx-auto mt-3 max-w-xl text-base leading-7 text-grayink">
                Albums added in the admin media library will appear here automatically.
              </p>
            </div>

            <div :if={@folders != []} class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
              <.folder_card
                :for={folder <- @folders}
                folder={folder}
                href={folder_path(@config.canonical_path, folder.name)}
              />
            </div>
          <% else %>
            <div class="mb-10 flex flex-wrap items-center justify-between gap-4">
              <h2 class="font-head text-2xl uppercase tracking-[0.08em] text-blueink">
                {@folder}
              </h2>
              <.link
                patch={@config.canonical_path}
                class="inline-flex items-center gap-2 font-head text-sm font-semibold uppercase tracking-[0.12em] text-blueink transition hover:text-crimson"
              >
                <.icon name="hero-arrow-left-mini" class="h-4 w-4" /> All albums
              </.link>
            </div>

            <div :if={@items == []} class="rounded-[8px] bg-ghost px-8 py-16 text-center">
              <h3 class="font-head text-2xl uppercase tracking-[0.08em] text-blueink">
                This album is empty
              </h3>
            </div>

            <div :if={@items != []} class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
              <.media_card :for={item <- @items} item={item} />
            </div>
          <% end %>
        </div>
      </section>

      <.site_footer base_path={~p"/"} />

      <.modal :if={@selected} id="media-lightbox" show on_cancel={JS.push("close")}>
        <img
          :if={@selected.media_type != "video"}
          src={@selected.image_url}
          alt={@selected.title}
          class="max-h-[70vh] w-full rounded-[6px] object-contain"
        />
        <div
          :if={@selected.media_type == "video" && VideoEmbed.embed_src(@selected.video_url)}
          class="aspect-video w-full overflow-hidden rounded-[6px] bg-black"
        >
          <iframe
            src={VideoEmbed.embed_src(@selected.video_url)}
            title={@selected.title}
            class="h-full w-full"
            frameborder="0"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
            referrerpolicy="strict-origin-when-cross-origin"
            allowfullscreen
          >
          </iframe>
        </div>
        <video
          :if={@selected.media_type == "video" && is_nil(VideoEmbed.embed_src(@selected.video_url))}
          src={@selected.video_url}
          poster={@selected.image_url}
          controls
          class="max-h-[70vh] w-full rounded-[6px] bg-black object-contain"
        >
        </video>
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
          <a
            :if={@selected.media_type != "video"}
            href={@selected.image_url}
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
        :if={@item.image_url}
        src={@item.image_url}
        alt={@item.title}
        loading="lazy"
        class="h-72 w-full object-cover object-[center_30%] transition duration-500 group-hover:scale-105"
      />
      <div
        :if={@item.media_type == "video" and is_nil(@item.image_url)}
        class="flex h-72 w-full items-center justify-center bg-blueink text-white"
      >
        <div class="text-center">
          <.icon name="hero-video-camera" class="mx-auto h-12 w-12" />
          <span class="mt-3 block font-head text-xs uppercase tracking-[0.2em]">Video</span>
        </div>
      </div>
      <span class="absolute inset-0 flex flex-col items-center justify-center gap-2 bg-blueink/0 px-4 text-center opacity-0 transition group-hover:bg-blueink/65 group-hover:opacity-100">
        <span class="font-head text-xs uppercase tracking-[0.2em] text-crimson">
          {@item.category}
        </span>
        <span class="font-head text-xl uppercase tracking-[0.04em] text-white">
          {@item.title}
        </span>
        <span
          :if={@item.media_type != "video"}
          class="font-head text-[11px] uppercase tracking-[0.22em] text-white/80"
        >
          View photo
        </span>
        <span
          :if={@item.media_type == "video"}
          class="font-head text-[11px] uppercase tracking-[0.22em] text-white/80"
        >
          Watch video
        </span>
      </span>
    </button>
    """
  end

  attr :folder, :map, required: true
  attr :href, :string, required: true

  defp folder_card(assigns) do
    ~H"""
    <.link
      patch={@href}
      class="group relative block overflow-hidden rounded-[6px] shadow-[0_15px_40px_rgba(15,30,80,0.08)]"
    >
      <img
        :if={@folder.cover}
        src={@folder.cover}
        alt={@folder.name}
        loading="lazy"
        class="h-72 w-full object-cover object-[center_30%] transition duration-500 group-hover:scale-105"
      />
      <div :if={!@folder.cover} class="flex h-72 w-full items-center justify-center bg-blueink text-white">
        <.icon name="hero-photo" class="h-12 w-12" />
      </div>
      <span class="absolute inset-x-0 bottom-0 flex flex-col gap-1 bg-gradient-to-t from-blueink/90 via-blueink/50 to-transparent px-5 pb-5 pt-16">
        <span class="font-head text-xl uppercase tracking-[0.04em] text-white">
          {@folder.name}
        </span>
        <span class="font-head text-[11px] uppercase tracking-[0.22em] text-white/80">
          {@folder.count} {if @folder.count == 1, do: "item", else: "items"} · View album
        </span>
      </span>
    </.link>
    """
  end

  defp present?(nil), do: false
  defp present?(value) when is_binary(value), do: String.trim(value) != ""

  defp scope_from_path(path) do
    cond do
      String.ends_with?(path, "/media/photos") ->
        %{
          media_type: "photo",
          title: "Photo Gallery",
          label: "Photos",
          all_label: "All Photos",
          canonical_path: "/media/photos",
          description: "Photography from the David Maraga campaign trail across Kenya."
        }

      String.ends_with?(path, "/media/videos") ->
        %{
          media_type: "video",
          title: "Video Gallery",
          label: "Videos",
          all_label: "All Videos",
          canonical_path: "/media/videos",
          description: "Watch campaign videos, speeches, and clips from the David Maraga trail."
        }

      true ->
        %{
          media_type: :all,
          title: "Media Gallery",
          label: "Media",
          all_label: "All Media",
          canonical_path: "/media",
          description: "Photography and video from the David Maraga campaign trail across Kenya."
        }
    end
  end
end
