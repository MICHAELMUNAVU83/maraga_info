defmodule MaragaInfoWeb.Admin.MediaLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfo.Content.MediaItem
  alias MaragaInfoWeb.Uploads

  @max_image_mb 8
  defp max_image_mb, do: @max_image_mb

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Media Library")
     |> assign(
       :page_subtitle,
       "Upload campaign photography for the public gallery, organise it by category, and control what shows."
     )
     |> assign(:show_form, false)
     |> assign(:editing, nil)
     |> assign(:image_url, nil)
     |> assign(:form, nil)
     |> load_items()
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: @max_image_mb * 1_000_000,
       auto_upload: true,
       progress: &handle_progress/3
     )}
  end

  @impl true
  def handle_params(_params, url, socket) do
    {:noreply, assign(socket, :current_path, URI.parse(url).path)}
  end

  ## Events

  @impl true
  def handle_event("new", _params, socket) do
    media_item = %MediaItem{}

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing, media_item)
     |> assign(:image_url, nil)
     |> assign_form(Content.change_media_item(media_item))}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    media_item = Content.get_media_item!(id)

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing, media_item)
     |> assign(:image_url, media_item.image_url)
     |> assign_form(Content.change_media_item(media_item))}
  end

  def handle_event("close_form", _params, socket) do
    {:noreply, assign(socket, show_form: false, editing: nil, image_url: nil, form: nil)}
  end

  def handle_event("validate", %{"media_item" => params}, socket) do
    changeset =
      socket.assigns.editing
      |> Content.change_media_item(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"media_item" => params}, socket) do
    params = maybe_put_image(params, socket.assigns.image_url)
    save_item(socket, socket.assigns.editing, params)
  end

  def handle_event("delete", %{"id" => id}, socket) do
    id
    |> Content.get_media_item!()
    |> Content.delete_media_item()

    {:noreply, load_items(socket)}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("remove_image", _params, socket) do
    {:noreply, assign(socket, :image_url, nil)}
  end

  ## Upload progress

  defp handle_progress(:image, entry, socket) do
    if entry.done? do
      url = consume_uploaded_entry(socket, entry, fn meta -> Uploads.store_entry(meta, entry) end)
      {:noreply, assign(socket, :image_url, url)}
    else
      {:noreply, socket}
    end
  end

  ## Persistence

  defp save_item(socket, %MediaItem{id: nil}, params) do
    case Content.create_media_item(params) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Media added")
         |> assign(show_form: false, editing: nil, image_url: nil, form: nil)
         |> load_items()}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_item(socket, %MediaItem{} = media_item, params) do
    case Content.update_media_item(media_item, params) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Media updated")
         |> assign(show_form: false, editing: nil, image_url: nil, form: nil)
         |> load_items()}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  ## Helpers

  defp load_items(socket) do
    items = Content.list_media_items()

    socket
    |> assign(:items, items)
    |> assign(:stats, item_stats(items))
  end

  defp item_stats(items) do
    Enum.reduce(items, %{total: length(items), published: 0, hidden: 0}, fn item, acc ->
      if item.is_published do
        Map.update!(acc, :published, &(&1 + 1))
      else
        Map.update!(acc, :hidden, &(&1 + 1))
      end
    end)
  end

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))

  defp maybe_put_image(params, nil), do: params
  defp maybe_put_image(params, ""), do: params
  defp maybe_put_image(params, url), do: Map.put(params, "image_url", url)

  defp upload_error_to_string(:too_large), do: "File is too large (max #{@max_image_mb}MB)"
  defp upload_error_to_string(:too_many_files), do: "Only one image allowed"
  defp upload_error_to_string(:not_accepted), do: "Unsupported file type"
  defp upload_error_to_string(_), do: "Invalid file"

  ## Render

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell
      page_title={@page_title}
      page_subtitle={@page_subtitle}
      current_user={@current_user}
      current_path={@current_path}
    >
      <:actions>
        <.link
          href={~p"/media"}
          target="_blank"
          class="inline-flex items-center gap-2 rounded-lg border border-zinc-200 px-3.5 py-2 text-sm font-medium text-zinc-700 transition hover:bg-zinc-50"
        >
          <.icon name="hero-arrow-top-right-on-square-mini" class="h-4 w-4" /> View gallery
        </.link>
        <button
          type="button"
          phx-click="new"
          class="inline-flex items-center gap-2 rounded-lg bg-blueink px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blueink/90"
        >
          <.icon name="hero-plus-mini" class="h-4 w-4" /> Add media
        </button>
      </:actions>

      <div class="space-y-6">
        <section class="grid gap-4 sm:grid-cols-3">
          <.admin_stat title="Total" value={Integer.to_string(@stats.total)} hint="All media" />
          <.admin_stat
            title="Published"
            value={Integer.to_string(@stats.published)}
            hint="Shown in the gallery"
            tone="accent"
          />
          <.admin_stat title="Hidden" value={Integer.to_string(@stats.hidden)} hint="Not public" />
        </section>

        <.admin_panel
          title="All media"
          subtitle="Add images and group them by category for the public gallery."
        >
          <div :if={@items != []} class="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            <div
              :for={item <- @items}
              class="group overflow-hidden rounded-xl border border-zinc-200 bg-white"
            >
              <div class="relative aspect-square overflow-hidden">
                <img src={item.image_url} alt={item.title} class="h-full w-full object-cover" />
                <span
                  :if={not item.is_published}
                  class="absolute left-2 top-2 rounded-full bg-zinc-900/80 px-2 py-0.5 text-xs font-medium text-white"
                >
                  Hidden
                </span>
              </div>
              <div class="p-3">
                <p class="truncate text-sm font-semibold text-zinc-900">{item.title}</p>
                <p class="mt-0.5 text-xs text-zinc-500">{item.category}</p>
                <div class="mt-3 flex items-center gap-3 text-xs font-medium">
                  <button
                    type="button"
                    phx-click="edit"
                    phx-value-id={item.id}
                    class="text-blueink hover:underline"
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    phx-click="delete"
                    phx-value-id={item.id}
                    data-confirm="Remove this media item?"
                    class="text-red-600 hover:underline"
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          </div>

          <.admin_empty_state
            :if={@items == []}
            title="No media yet"
            description="Upload the first image to start building the public gallery."
          />
        </.admin_panel>
      </div>

      <.modal :if={@show_form} id="media-form-modal" show on_cancel={JS.push("close_form")}>
        <h2 class="text-lg font-semibold text-zinc-900">
          {if @editing && @editing.id, do: "Edit media", else: "Add media"}
        </h2>

        <.form
          for={@form}
          id="media-form"
          phx-change="validate"
          phx-submit="save"
          class="mt-6 space-y-5"
        >
          <div>
            <div :if={@image_url} class="relative overflow-hidden rounded-lg border border-zinc-200">
              <img src={@image_url} class="aspect-video w-full object-cover" />
              <button
                type="button"
                phx-click="remove_image"
                class="absolute right-2 top-2 rounded-md bg-white/90 p-1.5 text-zinc-700 shadow-sm transition hover:text-red-600"
                aria-label="Remove image"
              >
                <.icon name="hero-x-mark-mini" class="h-4 w-4" />
              </button>
            </div>

            <label
              :if={!@image_url}
              class="flex cursor-pointer flex-col items-center justify-center gap-1 rounded-lg border border-dashed border-zinc-300 px-4 py-6 text-center text-sm text-zinc-600 transition hover:border-blueink hover:text-blueink"
            >
              <.icon name="hero-arrow-up-tray" class="h-5 w-5" />
              <span class="font-medium">Upload image</span>
              <span class="text-xs text-zinc-400">JPG, PNG or WEBP up to {max_image_mb()}MB</span>
              <.live_file_input upload={@uploads.image} class="sr-only" />
            </label>

            <p :for={entry <- @uploads.image.entries} class="mt-2 text-xs text-zinc-500">
              Uploading {entry.client_name} — {entry.progress}%
            </p>
            <p :for={err <- upload_errors(@uploads.image)} class="mt-2 text-xs text-red-600">
              {upload_error_to_string(err)}
            </p>
            <p
              :if={@form[:image_url].errors != [] && is_nil(@image_url)}
              class="mt-2 text-xs text-red-600"
            >
              An image is required.
            </p>
          </div>

          <.input field={@form[:title]} type="text" label="Title" />
          <.input
            field={@form[:category]}
            type="select"
            label="Category"
            options={MediaItem.categories()}
            prompt="Choose a category"
          />
          <.input field={@form[:description]} type="textarea" label="Description (optional)" rows="3" />
          <.input field={@form[:position]} type="number" label="Sort order" />
          <.input field={@form[:is_published]} type="checkbox" label="Show in public gallery" />

          <div class="flex items-center justify-end gap-3 pt-2">
            <button
              type="button"
              phx-click="close_form"
              class="rounded-lg px-4 py-2.5 text-sm font-medium text-zinc-600 transition hover:text-zinc-900"
            >
              Cancel
            </button>
            <button
              type="submit"
              phx-disable-with="Saving..."
              class="rounded-lg bg-blueink px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-blueink/90"
            >
              Save media
            </button>
          </div>
        </.form>
      </.modal>
    </.admin_shell>
    """
  end
end
