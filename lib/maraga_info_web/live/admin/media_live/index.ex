defmodule MaragaInfoWeb.Admin.MediaLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfo.Content.MediaItem
  alias MaragaInfoWeb.Uploads
  alias MaragaInfoWeb.VideoEmbed

  @max_image_mb 8
  @max_video_mb 80
  defp max_image_mb, do: @max_image_mb
  defp max_video_mb, do: @max_video_mb

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:scope, scope_from_path("/admin/media"))
     |> assign(:page_title, "Media Library")
     |> assign(:page_subtitle, "Upload and organise campaign media.")
     |> assign(:show_form, false)
     |> assign(:editing, nil)
     |> assign(:image_url, nil)
     |> assign(:video_url, nil)
     |> assign(:form, nil)
     |> assign(:items, [])
     |> assign(:stats, item_stats([]))
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: @max_image_mb * 1_000_000,
       auto_upload: true,
       progress: &handle_progress/3
     )
     |> allow_upload(:video,
       accept: ~w(.mp4 .mov .webm),
       max_entries: 1,
       max_file_size: @max_video_mb * 1_000_000,
       auto_upload: true,
       progress: &handle_progress/3
     )}
  end

  @impl true
  def handle_params(_params, url, socket) do
    path = URI.parse(url).path
    scope = scope_from_path(path)

    {:noreply,
     socket
     |> assign(:current_path, path)
     |> assign(:scope, scope)
     |> assign(:page_title, scope.title)
     |> assign(:page_subtitle, scope.subtitle)
     |> load_items()}
  end

  ## Events

  @impl true
  def handle_event("new", _params, socket) do
    media_item = %MediaItem{media_type: default_media_type(socket.assigns.scope)}

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing, media_item)
     |> assign(:image_url, nil)
     |> assign(:video_url, nil)
     |> assign_form(Content.change_media_item(media_item))}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    media_item = Content.get_media_item!(id)

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing, media_item)
     |> assign(:image_url, media_item.image_url)
     |> assign(:video_url, media_item.video_url)
     |> assign_form(Content.change_media_item(media_item))}
  end

  def handle_event("close_form", _params, socket) do
    {:noreply,
     assign(socket, show_form: false, editing: nil, image_url: nil, video_url: nil, form: nil)}
  end

  def handle_event("validate", %{"media_item" => params}, socket) do
    params =
      params
      |> maybe_lock_media_type(socket.assigns.scope)
      |> maybe_put_image(socket.assigns.image_url)
      |> maybe_put_video(socket.assigns.video_url)

    changeset =
      socket.assigns.editing
      |> Content.change_media_item(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"media_item" => params}, socket) do
    params =
      params
      |> maybe_lock_media_type(socket.assigns.scope)
      |> maybe_put_image(socket.assigns.image_url)
      |> maybe_put_video(socket.assigns.video_url)

    save_item(socket, socket.assigns.editing, params)
  end

  def handle_event("delete", %{"id" => id}, socket) do
    id
    |> Content.get_media_item!()
    |> Content.delete_media_item()

    {:noreply,
     socket |> put_flash(:info, "#{socket.assigns.scope.singular} deleted") |> load_items()}
  end

  def handle_event("cancel_upload", %{"upload" => name, "ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, String.to_existing_atom(name), ref)}
  end

  def handle_event("remove_image", _params, socket) do
    {:noreply, assign(socket, :image_url, nil)}
  end

  def handle_event("remove_video", _params, socket) do
    {:noreply, assign(socket, :video_url, nil)}
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

  defp handle_progress(:video, entry, socket) do
    if entry.done? do
      url = consume_uploaded_entry(socket, entry, fn meta -> Uploads.store_entry(meta, entry) end)
      {:noreply, assign(socket, :video_url, url)}
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
         |> put_flash(:info, "#{socket.assigns.scope.singular} added")
         |> assign(show_form: false, editing: nil, image_url: nil, video_url: nil, form: nil)
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
         |> put_flash(:info, "#{socket.assigns.scope.singular} updated")
         |> assign(show_form: false, editing: nil, image_url: nil, video_url: nil, form: nil)
         |> load_items()}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  ## Helpers

  defp load_items(socket) do
    items = Content.list_media_items(media_type: socket.assigns.scope.media_type)

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

  defp maybe_lock_media_type(params, %{media_type: media_type})
       when media_type in ["photo", "video"],
       do: Map.put(params, "media_type", media_type)

  defp maybe_lock_media_type(params, _scope), do: params

  defp maybe_put_image(params, nil), do: params
  defp maybe_put_image(params, ""), do: params
  defp maybe_put_image(params, url), do: Map.put(params, "image_url", url)

  defp maybe_put_video(params, nil), do: params
  defp maybe_put_video(params, ""), do: params
  defp maybe_put_video(params, url), do: Map.put(params, "video_url", url)

  defp default_media_type(%{media_type: media_type}) when media_type in ["photo", "video"],
    do: media_type

  defp default_media_type(_scope), do: "photo"

  defp current_media_type(form, scope) do
    Phoenix.HTML.Form.input_value(form, :media_type) || default_media_type(scope)
  end

  defp current_video(video_url, _form) when is_binary(video_url) and video_url != "",
    do: video_url

  defp current_video(_video_url, form), do: Phoenix.HTML.Form.input_value(form, :video_url)

  defp current_image(image_url, _form) when is_binary(image_url) and image_url != "",
    do: image_url

  defp current_image(_image_url, form), do: Phoenix.HTML.Form.input_value(form, :image_url)

  defp scope_from_path(path) do
    cond do
      String.starts_with?(path, "/admin/media/photos") ->
        %{
          title: "Photos",
          subtitle: "Upload and organise campaign photography for the public gallery.",
          panel_title: "All photos",
          panel_subtitle: "Manage campaign photography, visibility, and display order.",
          base_path: "/admin/media/photos",
          gallery_path: "/media/photos",
          media_type: "photo",
          singular: "Photo",
          new_label: "Add photo"
        }

      String.starts_with?(path, "/admin/media/videos") ->
        %{
          title: "Videos",
          subtitle:
            "Upload campaign videos and optional thumbnails for the public media archive.",
          panel_title: "All videos",
          panel_subtitle: "Manage uploaded clips, thumbnails, and public visibility.",
          base_path: "/admin/media/videos",
          gallery_path: "/media/videos",
          media_type: "video",
          singular: "Video",
          new_label: "Add video"
        }

      true ->
        %{
          title: "Media Library",
          subtitle:
            "Upload campaign photography and video, organise it by category, and control what shows.",
          panel_title: "All media",
          panel_subtitle: "Add photos and videos, then group them for the public gallery.",
          base_path: "/admin/media",
          gallery_path: "/media",
          media_type: :all,
          singular: "Media item",
          new_label: "Add media"
        }
    end
  end

  defp upload_error_to_string(:too_large), do: "File is too large"
  defp upload_error_to_string(:too_many_files), do: "Only one file allowed"
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
          href={@scope.gallery_path}
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
          <.icon name="hero-plus-mini" class="h-4 w-4" /> {@scope.new_label}
        </button>
      </:actions>

      <div class="space-y-6">
        <section class="grid gap-4 sm:grid-cols-3">
          <.admin_stat title="Total" value={Integer.to_string(@stats.total)} hint="In this section" />
          <.admin_stat
            title="Published"
            value={Integer.to_string(@stats.published)}
            hint="Shown publicly"
            tone="accent"
          />
          <.admin_stat title="Hidden" value={Integer.to_string(@stats.hidden)} hint="Not public" />
        </section>

        <.admin_panel title={@scope.panel_title} subtitle={@scope.panel_subtitle}>
          <div :if={@items != []} class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
            <div
              :for={item <- @items}
              class="group overflow-hidden rounded-xl border border-zinc-200 bg-white"
            >
              <div class="relative aspect-video overflow-hidden bg-zinc-100">
                <img
                  :if={item.image_url}
                  src={item.image_url}
                  alt={item.title}
                  class="h-full w-full object-cover"
                />
                <div
                  :if={item.media_type == "video" and is_nil(item.image_url)}
                  class="flex h-full items-center justify-center bg-blueink text-white"
                >
                  <div class="text-center">
                    <.icon name="hero-video-camera" class="mx-auto h-10 w-10" />
                    <p class="mt-2 font-head text-xs uppercase tracking-[0.18em]">Video</p>
                  </div>
                </div>
                <span class="absolute left-2 top-2 rounded-full bg-white/90 px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-blueink">
                  {item.media_type}
                </span>
                <span
                  :if={not item.is_published}
                  class="absolute right-2 top-2 rounded-full bg-zinc-900/80 px-2 py-0.5 text-xs font-medium text-white"
                >
                  Hidden
                </span>
              </div>
              <div class="p-4">
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
            title={"No " <> String.downcase(@scope.title) <> " yet"}
            description={"Add the first " <> String.downcase(@scope.singular) <> " to populate this section."}
          />
        </.admin_panel>
      </div>

      <.modal :if={@show_form} id="media-form-modal" show on_cancel={JS.push("close_form")}>
        <h2 class="text-lg font-semibold text-zinc-900">
          {if @editing && @editing.id,
            do: "Edit " <> String.downcase(@scope.singular),
            else: @scope.new_label}
        </h2>

        <.form
          for={@form}
          id="media-form"
          phx-change="validate"
          phx-submit="save"
          class="mt-6 space-y-5"
        >
          <input
            :if={@scope.media_type in ["photo", "video"]}
            type="hidden"
            name="media_item[media_type]"
            value={@scope.media_type}
          />

          <.input
            :if={@scope.media_type == :all}
            field={@form[:media_type]}
            type="select"
            label="Media type"
            options={Enum.map(MediaItem.media_types(), &{String.capitalize(&1), &1})}
          />

          <div :if={current_media_type(@form, @scope) == "photo"}>
            <div
              :if={current_image(@image_url, @form)}
              class="relative overflow-hidden rounded-lg border border-zinc-200"
            >
              <img src={current_image(@image_url, @form)} class="aspect-video w-full object-cover" />
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
              :if={!current_image(@image_url, @form)}
              class="flex cursor-pointer flex-col items-center justify-center gap-1 rounded-lg border border-dashed border-zinc-300 px-4 py-6 text-center text-sm text-zinc-600 transition hover:border-blueink hover:text-blueink"
            >
              <.icon name="hero-arrow-up-tray" class="h-5 w-5" />
              <span class="font-medium">Upload photo</span>
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
              :if={@form[:image_url].errors != [] && is_nil(current_image(@image_url, @form))}
              class="mt-2 text-xs text-red-600"
            >
              A photo is required.
            </p>
          </div>

          <div :if={current_media_type(@form, @scope) == "video"} class="space-y-4">
            <div
              :if={
                current_video(@video_url, @form) &&
                  VideoEmbed.embed_src(current_video(@video_url, @form))
              }
              class="overflow-hidden rounded-lg border border-zinc-200 bg-black"
            >
              <iframe
                src={VideoEmbed.embed_src(current_video(@video_url, @form))}
                title="Video preview"
                class="aspect-video w-full"
                frameborder="0"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                referrerpolicy="strict-origin-when-cross-origin"
                allowfullscreen
              >
              </iframe>
            </div>
            <div
              :if={
                current_video(@video_url, @form) &&
                  is_nil(VideoEmbed.embed_src(current_video(@video_url, @form)))
              }
              class="relative overflow-hidden rounded-lg border border-zinc-200 bg-black"
            >
              <video src={current_video(@video_url, @form)} controls class="aspect-video w-full">
              </video>
              <button
                type="button"
                phx-click="remove_video"
                class="absolute right-2 top-2 rounded-md bg-white/90 p-1.5 text-zinc-700 shadow-sm transition hover:text-red-600"
                aria-label="Remove video"
              >
                <.icon name="hero-x-mark-mini" class="h-4 w-4" />
              </button>
            </div>

            <label
              :if={!current_video(@video_url, @form)}
              class="flex cursor-pointer flex-col items-center justify-center gap-1 rounded-lg border border-dashed border-zinc-300 px-4 py-6 text-center text-sm text-zinc-600 transition hover:border-blueink hover:text-blueink"
            >
              <.icon name="hero-arrow-up-tray" class="h-5 w-5" />
              <span class="font-medium">Upload video</span>
              <span class="text-xs text-zinc-400">
                MP4, MOV or WEBM up to {max_video_mb()}MB
              </span>
              <.live_file_input upload={@uploads.video} class="sr-only" />
            </label>

            <div class="space-y-1">
              <label class="block text-xs font-medium text-zinc-600">
                Or paste a YouTube / Vimeo link
              </label>
              <.input
                field={@form[:video_url]}
                type="text"
                placeholder="https://www.youtube.com/watch?v=…"
              />
              <p class="text-xs text-zinc-400">
                The video will play inline on the site. Leave the upload empty when using a link.
              </p>
            </div>

            <p :for={entry <- @uploads.video.entries} class="text-xs text-zinc-500">
              Uploading {entry.client_name} — {entry.progress}%
            </p>
            <p :for={err <- upload_errors(@uploads.video)} class="text-xs text-red-600">
              {upload_error_to_string(err)}
            </p>
            <p
              :if={@form[:video_url].errors != [] && is_nil(current_video(@video_url, @form))}
              class="text-xs text-red-600"
            >
              A video file is required.
            </p>

            <div>
              <div
                :if={current_image(@image_url, @form)}
                class="relative overflow-hidden rounded-lg border border-zinc-200"
              >
                <img src={current_image(@image_url, @form)} class="aspect-video w-full object-cover" />
                <button
                  type="button"
                  phx-click="remove_image"
                  class="absolute right-2 top-2 rounded-md bg-white/90 p-1.5 text-zinc-700 shadow-sm transition hover:text-red-600"
                  aria-label="Remove thumbnail"
                >
                  <.icon name="hero-x-mark-mini" class="h-4 w-4" />
                </button>
              </div>

              <label
                :if={!current_image(@image_url, @form)}
                class="mt-2 flex cursor-pointer flex-col items-center justify-center gap-1 rounded-lg border border-dashed border-zinc-300 px-4 py-6 text-center text-sm text-zinc-600 transition hover:border-blueink hover:text-blueink"
              >
                <.icon name="hero-photo" class="h-5 w-5" />
                <span class="font-medium">Upload thumbnail (optional)</span>
                <span class="text-xs text-zinc-400">Used on the listing and video modal cover</span>
                <.live_file_input upload={@uploads.image} class="sr-only" />
              </label>
            </div>
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
          <.input field={@form[:display_on_landing]} type="checkbox" label="Display on landing page" />

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
              Save {String.downcase(@scope.singular)}
            </button>
          </div>
        </.form>
      </.modal>
    </.admin_shell>
    """
  end
end
