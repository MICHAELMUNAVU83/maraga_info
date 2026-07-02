defmodule MaragaInfoWeb.Admin.EventLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfo.Content.Event
  alias MaragaInfoWeb.Uploads

  @max_image_mb 8
  defp max_image_mb, do: @max_image_mb

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Events")
     |> assign(:page_subtitle, "Schedule and publish campaign events for the public calendar.")
     |> assign(:show_form, false)
     |> assign(:editing, nil)
     |> assign(:form, nil)
     |> assign(:image_url, nil)
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: @max_image_mb * 1_000_000,
       auto_upload: true,
       progress: &handle_progress/3
     )
     |> load_events()}
  end

  @impl true
  def handle_params(_params, url, socket) do
    {:noreply, assign(socket, :current_path, URI.parse(url).path)}
  end

  @impl true
  def handle_event("new", _params, socket) do
    event = %Event{}

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing, event)
     |> assign(:image_url, nil)
     |> assign_form(Content.change_event(event))}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    event = Content.get_event!(id)

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing, event)
     |> assign(:image_url, event.image_url)
     |> assign_form(Content.change_event(event))}
  end

  def handle_event("close_form", _params, socket) do
    {:noreply, assign(socket, show_form: false, editing: nil, form: nil, image_url: nil)}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("remove_image", _params, socket) do
    {:noreply, assign(socket, :image_url, nil)}
  end

  def handle_event("validate", %{"event" => params}, socket) do
    changeset =
      socket.assigns.editing
      |> Content.change_event(normalize_params(params))
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"event" => params}, socket) do
    params =
      params
      |> normalize_params()
      |> Map.put("image_url", socket.assigns.image_url)

    save_event(socket, socket.assigns.editing, params)
  end

  def handle_event("delete", %{"id" => id}, socket) do
    id
    |> Content.get_event!()
    |> Content.delete_event()

    {:noreply, socket |> put_flash(:info, "Event deleted") |> load_events()}
  end

  defp handle_progress(:image, entry, socket) do
    if entry.done? do
      url = consume_uploaded_entry(socket, entry, fn meta -> Uploads.store_entry(meta, entry) end)
      {:noreply, assign(socket, :image_url, url)}
    else
      {:noreply, socket}
    end
  end

  defp save_event(socket, %Event{id: nil}, params) do
    case Content.create_event(params) do
      {:ok, _event} ->
        {:noreply,
         socket
         |> put_flash(:info, "Event added")
         |> assign(show_form: false, editing: nil, form: nil, image_url: nil)
         |> load_events()}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_event(socket, %Event{} = event, params) do
    case Content.update_event(event, params) do
      {:ok, _event} ->
        {:noreply,
         socket
         |> put_flash(:info, "Event updated")
         |> assign(show_form: false, editing: nil, form: nil, image_url: nil)
         |> load_events()}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp load_events(socket) do
    assign(socket, :events, Content.list_events())
  end

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))

  defp image_errors(upload) do
    Enum.flat_map(upload.entries, &upload_errors(upload, &1)) ++ upload_errors(upload)
  end

  defp upload_error_to_string(:too_large), do: "File is too large (max #{@max_image_mb}MB)"
  defp upload_error_to_string(:too_many_files), do: "Too many files"
  defp upload_error_to_string(:not_accepted), do: "Unsupported file type"
  defp upload_error_to_string(_), do: "Invalid file"

  # `datetime-local` inputs send "YYYY-MM-DDTHH:MM" with no timezone; turn those
  # into UTC datetimes the schema can cast.
  defp normalize_params(params) do
    params
    |> Map.update("starts_at", nil, &to_utc/1)
    |> Map.update("ends_at", nil, &to_utc/1)
  end

  defp to_utc(value) when is_binary(value) do
    case NaiveDateTime.from_iso8601(ensure_seconds(value)) do
      {:ok, naive} -> DateTime.from_naive!(naive, "Etc/UTC")
      _ -> value
    end
  end

  defp to_utc(value), do: value

  defp ensure_seconds(value) do
    case String.split(value, ":") do
      [_h, _m] -> value <> ":00"
      _ -> value
    end
  end

  defp format_range(%Event{all_day: true} = event),
    do: Calendar.strftime(event.starts_at, "%d %b %Y") <> " · All day"

  defp format_range(%Event{ends_at: nil} = event),
    do: Calendar.strftime(event.starts_at, "%d %b %Y, %-I:%M %p")

  defp format_range(%Event{} = event),
    do:
      Calendar.strftime(event.starts_at, "%d %b %Y, %-I:%M %p") <>
        " – " <> Calendar.strftime(event.ends_at, "%-I:%M %p")

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
          href="/events"
          target="_blank"
          class="inline-flex items-center gap-2 rounded-lg border border-zinc-200 px-3.5 py-2 text-sm font-medium text-zinc-700 transition hover:bg-zinc-50"
        >
          <.icon name="hero-arrow-top-right-on-square-mini" class="h-4 w-4" /> View calendar
        </.link>
        <button
          type="button"
          phx-click="new"
          class="inline-flex items-center gap-2 rounded-lg bg-blueink px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blueink/90"
        >
          <.icon name="hero-plus-mini" class="h-4 w-4" /> New event
        </button>
      </:actions>

      <.admin_panel title="All events" subtitle="Manage scheduled campaign events and visibility.">
        <div :if={@events != []} class="divide-y divide-zinc-100">
          <div
            :for={event <- @events}
            class="flex flex-col gap-3 py-4 sm:flex-row sm:items-center sm:justify-between"
          >
            <div class="min-w-0">
              <div class="flex items-center gap-2">
                <p class="truncate text-sm font-semibold text-zinc-900">{event.title}</p>
                <.admin_badge
                  tone={if event.is_published, do: "published", else: "draft"}
                  label={if event.is_published, do: "published", else: "hidden"}
                />
              </div>
              <p class="mt-0.5 text-xs text-zinc-500">{format_range(event)}</p>
              <p :if={event.location} class="text-xs text-zinc-400">{event.location}</p>
            </div>
            <div class="flex shrink-0 items-center gap-3 text-xs font-medium">
              <button
                type="button"
                phx-click="edit"
                phx-value-id={event.id}
                class="text-blueink hover:underline"
              >
                Edit
              </button>
              <button
                type="button"
                phx-click="delete"
                phx-value-id={event.id}
                data-confirm="Remove this event?"
                class="text-red-600 hover:underline"
              >
                Delete
              </button>
            </div>
          </div>
        </div>

        <.admin_empty_state
          :if={@events == []}
          title="No events yet"
          description="Add the first campaign event to populate the public calendar."
        />
      </.admin_panel>

      <.modal :if={@show_form} id="event-form-modal" show on_cancel={JS.push("close_form")}>
        <h2 class="text-lg font-semibold text-zinc-900">
          {if @editing && @editing.id, do: "Edit event", else: "New event"}
        </h2>

        <.form
          for={@form}
          id="event-form"
          phx-change="validate"
          phx-submit="save"
          class="mt-6 space-y-5"
        >
          <.input field={@form[:title]} type="text" label="Title" />
          <.input field={@form[:location]} type="text" label="Location (optional)" />

          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:starts_at]} type="datetime-local" label="Starts at" />
            <.input field={@form[:ends_at]} type="datetime-local" label="Ends at (optional)" />
          </div>

          <.input field={@form[:description]} type="textarea" label="Description (optional)" rows="3" />

          <div>
            <label class="mb-1 block text-sm font-medium text-zinc-700">Photo (optional)</label>

            <div
              :if={@image_url}
              class="relative mb-3 overflow-hidden rounded-lg border border-zinc-200"
            >
              <img src={@image_url} class="mx-auto max-h-64 w-full object-contain" />
              <button
                type="button"
                phx-click="remove_image"
                class="absolute right-2 top-2 rounded-md bg-white/90 p-1 text-zinc-700 shadow-sm transition hover:text-red-600"
                aria-label="Remove photo"
              >
                <.icon name="hero-x-mark-mini" class="h-4 w-4" />
              </button>
            </div>

            <label class="flex cursor-pointer flex-col items-center justify-center gap-1 rounded-lg border border-dashed border-zinc-300 px-4 py-6 text-center text-sm text-zinc-600 transition hover:border-blueink hover:text-blueink">
              <.icon name="hero-arrow-up-tray" class="h-5 w-5" />
              <span class="font-medium">
                {if @image_url, do: "Replace photo", else: "Upload photo"}
              </span>
              <span class="text-xs text-zinc-400">JPG, PNG or WEBP up to {max_image_mb()}MB</span>
              <.live_file_input upload={@uploads.image} class="sr-only" />
            </label>

            <p :for={entry <- @uploads.image.entries} class="mt-2 text-xs text-zinc-500">
              Uploading {entry.client_name} — {entry.progress}%
            </p>

            <p :for={err <- image_errors(@uploads.image)} class="mt-1 text-xs text-red-600">
              {upload_error_to_string(err)}
            </p>
          </div>

          <.input field={@form[:all_day]} type="checkbox" label="All-day event" />
          <.input field={@form[:is_published]} type="checkbox" label="Show on public calendar" />

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
              Save event
            </button>
          </div>
        </.form>
      </.modal>
    </.admin_shell>
    """
  end
end
