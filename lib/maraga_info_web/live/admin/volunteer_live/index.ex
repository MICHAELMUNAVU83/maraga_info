defmodule MaragaInfoWeb.Admin.VolunteerLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Volunteers
  alias MaragaInfo.Volunteers.Volunteer
  alias Phoenix.LiveView.JS

  @page_size 25

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Volunteers")
     |> assign(
       :page_subtitle,
       "Search the full volunteer database, then add people one by one or import more from Excel when needed."
     )
     |> assign(:show_form, false)
     |> assign(:access_granted, false)
     |> assign(:access_email, "")
     |> assign(:access_requested, false)
     |> assign(:access_error, nil)
     |> assign(:query, "")
     |> assign(:page, 1)
     |> assign(:per_page, @page_size)
     |> assign_empty_data()
     |> assign_form(Volunteers.change_volunteer(%Volunteer{}))
     |> allow_upload(:spreadsheet,
       accept: ~w(.xlsx),
       max_entries: 1,
       auto_upload: false
     )
     |> load_access_history()}
  end

  @impl true
  def handle_params(_params, url, socket) do
    {:noreply, assign(socket, :current_path, URI.parse(url).path)}
  end

  @impl true
  def handle_event("validate_manual", %{"volunteer" => params}, socket) do
    changeset =
      %Volunteer{}
      |> Volunteers.change_volunteer(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("request_access_code", %{"access" => %{"email" => email}}, socket) do
    case Volunteers.request_volunteer_access_code(email) do
      {:ok, access_code} ->
        {:noreply,
         socket
         |> assign(:access_email, access_code.email)
         |> assign(:access_requested, true)
         |> assign(:access_error, nil)
         |> put_flash(:info, "Access code sent to #{access_code.email}. It expires in 2 minutes.")}

      {:error, :invalid_email} ->
        {:noreply, assign(socket, :access_error, "Enter a valid email address.")}

      {:error, _reason} ->
        {:noreply, assign(socket, :access_error, "Could not send the access code. Try again.")}
    end
  end

  def handle_event("verify_access_code", %{"access" => params}, socket) do
    email = Map.get(params, "email", socket.assigns.access_email)
    code = Map.get(params, "code", "")

    case Volunteers.verify_volunteer_access_code(email, code) do
      {:ok, _view} ->
        {:noreply,
         socket
         |> assign(:access_granted, true)
         |> assign(:access_email, email)
         |> assign(:access_error, nil)
         |> assign(:access_requested, false)
         |> load_data()
         |> load_access_history()
         |> put_flash(:info, "Volunteer list unlocked.")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:access_email, email)
         |> assign(:access_requested, true)
         |> assign(
           :access_error,
           "That code is invalid or has expired. Request a new code if needed."
         )}
    end
  end

  def handle_event("open_form_modal", _params, socket) do
    {:noreply, assign(socket, :show_form, true)}
  end

  def handle_event("close_form_modal", _params, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  def handle_event("save_manual", %{"volunteer" => params}, socket) do
    case Volunteers.create_volunteer(params) do
      {:ok, _volunteer} ->
        {:noreply,
         socket
         |> assign(:page, 1)
         |> assign(:show_form, false)
         |> put_flash(:info, "Volunteer added")
         |> assign_form(Volunteers.change_volunteer(%Volunteer{}))
         |> load_data()}

      {:error, changeset} ->
        {:noreply, socket |> assign(:show_form, true) |> assign_form(changeset)}
    end
  end

  def handle_event("search", %{"q" => query}, socket) do
    {:noreply, socket |> assign(:query, query) |> assign(:page, 1) |> load_data()}
  end

  def handle_event("prev_page", _params, socket) do
    {:noreply, socket |> update(:page, &max(&1 - 1, 1)) |> load_data()}
  end

  def handle_event("next_page", _params, socket) do
    {:noreply, socket |> update(:page, &(&1 + 1)) |> load_data()}
  end

  def handle_event("go_page", %{"page" => page}, socket) do
    page =
      page
      |> to_string()
      |> Integer.parse()
      |> case do
        {value, _rest} -> value
        :error -> 1
      end

    {:noreply, socket |> assign(:page, page) |> load_data()}
  end

  def handle_event("import", _params, socket) do
    case consume_uploaded_entries(socket, :spreadsheet, fn %{path: path}, _entry ->
           {:ok, Volunteers.import_volunteers_from_file(path)}
         end) do
      [] ->
        {:noreply, put_flash(socket, :error, "Choose an .xlsx file before importing.")}

      [result] ->
        handle_import_result(socket, result)
    end
  end

  defp handle_import_result(socket, {:ok, summary}) do
    socket =
      socket
      |> assign(:page, 1)
      |> assign(:show_form, false)
      |> load_data()
      |> put_flash(:info, import_message(summary))

    socket =
      if summary.failed > 0 do
        put_flash(socket, :error, Enum.join(summary.errors, " | "))
      else
        socket
      end

    {:noreply, socket}
  end

  defp handle_import_result(socket, {:error, :invalid_spreadsheet}) do
    {:noreply,
     put_flash(socket, :error, "The uploaded file could not be read as an Excel sheet.")}
  end

  defp load_data(socket) do
    total_entries = Volunteers.count_volunteers(query: socket.assigns.query)
    total_pages = total_pages(total_entries, socket.assigns.per_page)
    page = socket.assigns.page |> max(1) |> min(total_pages)
    offset = (page - 1) * socket.assigns.per_page

    socket
    |> assign(:stats, Volunteers.volunteer_stats())
    |> assign(:page, page)
    |> assign(:total_entries, total_entries)
    |> assign(:total_pages, total_pages)
    |> assign(:page_numbers, page_numbers(page, total_pages))
    |> assign(:first_entry, first_entry(total_entries, offset))
    |> assign(:last_entry, last_entry(total_entries, offset, socket.assigns.per_page))
    |> assign(
      :volunteers,
      Volunteers.list_volunteers(
        query: socket.assigns.query,
        limit: socket.assigns.per_page,
        offset: offset
      )
    )
  end

  defp load_access_history(socket) do
    assign(socket, :recent_views, Volunteers.list_volunteer_views(limit: 10))
  end

  defp assign_empty_data(socket) do
    socket
    |> assign(:stats, %{total: 0, with_phone: 0, with_location: 0, with_notes: 0})
    |> assign(:total_entries, 0)
    |> assign(:total_pages, 1)
    |> assign(:page_numbers, [1])
    |> assign(:first_entry, 0)
    |> assign(:last_entry, 0)
    |> assign(:volunteers, [])
  end

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))

  defp import_message(summary) do
    parts = [
      "#{summary.inserted} added",
      "#{summary.updated} updated"
    ]

    parts =
      if summary.failed > 0 do
        parts ++ ["#{summary.failed} failed"]
      else
        parts
      end

    "Import finished: #{Enum.join(parts, ", ")}."
  end

  defp volunteer_name(%Volunteer{full_name: full_name})
       when is_binary(full_name) and full_name != "",
       do: full_name

  defp volunteer_name(%Volunteer{} = volunteer) do
    [volunteer.first_name, volunteer.last_name]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> case do
      "" -> volunteer.email
      value -> value
    end
  end

  defp location_summary(%Volunteer{} = volunteer) do
    [volunteer.county, volunteer.constituency, volunteer.ward]
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.join(" · ")
  end

  defp format_date(nil), do: "Not set"
  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%d %b %Y")

  defp format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%d %b %Y %H:%M UTC")
  end

  defp upload_error_to_string(:too_large), do: "File is too large"
  defp upload_error_to_string(:too_many_files), do: "Only one file can be uploaded at a time"
  defp upload_error_to_string(:not_accepted), do: "Only .xlsx files are allowed"
  defp upload_error_to_string(_error), do: "Invalid file"

  defp total_pages(0, _per_page), do: 1
  defp total_pages(total_entries, per_page), do: ceil(total_entries / per_page)

  defp page_numbers(page, total_pages) do
    start_page = max(page - 2, 1)
    end_page = min(start_page + 4, total_pages)
    start_page = max(end_page - 4, 1)
    Enum.to_list(start_page..end_page)
  end

  defp first_entry(0, _offset), do: 0
  defp first_entry(_total_entries, offset), do: offset + 1

  defp last_entry(total_entries, offset, per_page) do
    min(offset + per_page, total_entries)
  end

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
        <button
          id="open-volunteer-modal"
          type="button"
          phx-click="open_form_modal"
          class="inline-flex items-center gap-2 rounded-lg bg-blueink px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blueink/90"
        >
          <.icon name="hero-plus-mini" class="h-4 w-4" /> Add or import volunteers
        </button>
      </:actions>

      <div class="space-y-6">
        <.admin_panel
          :if={!@access_granted}
          title="Volunteer list locked"
          subtitle="Enter your email and the access code sent to you before viewing volunteer records."
        >
          <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div class="max-w-2xl text-sm text-zinc-600">
              Volunteer details are protected with a short-lived email code. Each successful unlock is tracked below.
            </div>
            <button
              type="button"
              phx-click={JS.show(to: "#volunteer-access-modal")}
              class="inline-flex items-center justify-center gap-2 rounded-lg bg-blueink px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blueink/90"
            >
              <.icon name="hero-lock-open" class="h-4 w-4" /> Unlock list
            </button>
          </div>
        </.admin_panel>

        <.admin_panel
          title="Recent volunteer views"
          subtitle="Successful unlocks of the volunteer database."
        >
          <div :if={@recent_views != []} class="overflow-x-auto">
            <table class="min-w-full divide-y divide-zinc-200 text-sm">
              <thead class="bg-zinc-50 text-left text-xs uppercase tracking-wide text-zinc-500">
                <tr>
                  <th class="px-3 py-3 font-medium">Viewer</th>
                  <th class="px-3 py-3 font-medium">Viewed</th>
                  <th class="px-3 py-3 font-medium">Method</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-zinc-100">
                <tr :for={view <- @recent_views}>
                  <td class="px-3 py-3 align-top font-medium text-zinc-900">{view.email}</td>
                  <td class="px-3 py-3 align-top text-zinc-600">{format_datetime(view.viewed_at)}</td>
                  <td class="px-3 py-3 align-top text-zinc-600">{view.access_method}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <.admin_empty_state
            :if={@recent_views == []}
            title="No volunteer views yet"
            description="Unlocks will appear here after a code is verified."
          />
        </.admin_panel>

        <div :if={@access_granted} class="space-y-6">
          <section class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <.admin_stat title="Total" value={Integer.to_string(@stats.total)} hint="All volunteers" />
            <.admin_stat
              title="With phone"
              value={Integer.to_string(@stats.with_phone)}
              hint="Reachable contacts"
              tone="accent"
            />
            <.admin_stat
              title="With location"
              value={Integer.to_string(@stats.with_location)}
              hint="County captured"
            />
            <.admin_stat
              title="With notes"
              value={Integer.to_string(@stats.with_notes)}
              hint="Extra context supplied"
            />
          </section>

          <.admin_panel
            title="Volunteer list"
            subtitle={"Showing #{@first_entry}-#{@last_entry} of #{@total_entries} volunteers. Use search to narrow by name, email, phone, county, or constituency."}
          >
            <:actions>
              <.form for={%{}} phx-change="search" class="w-full sm:w-72">
                <input
                  type="search"
                  name="q"
                  value={@query}
                  placeholder="Search volunteers"
                  class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                />
              </.form>
            </:actions>

            <div :if={@volunteers != []} class="overflow-x-auto">
              <table class="min-w-full divide-y divide-zinc-200 text-sm">
                <thead class="bg-zinc-50 text-left text-xs uppercase tracking-wide text-zinc-500">
                  <tr>
                    <th class="px-3 py-3 font-medium">Volunteer</th>
                    <th class="px-3 py-3 font-medium">Location</th>
                    <th class="px-3 py-3 font-medium">Phone</th>
                    <th class="px-3 py-3 font-medium">Joined</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-zinc-100">
                  <tr :for={volunteer <- @volunteers}>
                    <td class="px-3 py-3 align-top">
                      <p class="font-medium text-zinc-900">{volunteer_name(volunteer)}</p>
                      <p class="text-zinc-500">{volunteer.email}</p>
                    </td>
                    <td class="px-3 py-3 align-top text-zinc-600">
                      {location_summary(volunteer)}
                      <p :if={volunteer.polling_station} class="mt-1 text-xs text-zinc-500">
                        {volunteer.polling_station}
                      </p>
                    </td>
                    <td class="px-3 py-3 align-top text-zinc-600">{volunteer.phone || "Not set"}</td>
                    <td class="px-3 py-3 align-top text-zinc-600">
                      {format_date(volunteer.joined_on)}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div
              :if={@volunteers != []}
              class="mt-4 flex flex-col gap-3 border-t border-zinc-100 pt-4 sm:flex-row sm:items-center sm:justify-between"
            >
              <p class="text-sm text-zinc-500">
                Page {@page} of {@total_pages}
              </p>

              <div class="flex flex-wrap items-center gap-2">
                <button
                  type="button"
                  phx-click="prev_page"
                  disabled={@page <= 1}
                  class="rounded-lg border border-zinc-200 px-3 py-2 text-sm font-medium text-zinc-700 transition hover:bg-zinc-50 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  Previous
                </button>

                <button
                  :for={page_number <- @page_numbers}
                  type="button"
                  phx-click="go_page"
                  phx-value-page={page_number}
                  class={[
                    "rounded-lg px-3 py-2 text-sm font-medium transition",
                    page_number == @page &&
                      "bg-blueink text-white",
                    page_number != @page &&
                      "border border-zinc-200 text-zinc-700 hover:bg-zinc-50"
                  ]}
                >
                  {page_number}
                </button>

                <button
                  type="button"
                  phx-click="next_page"
                  disabled={@page >= @total_pages}
                  class="rounded-lg border border-zinc-200 px-3 py-2 text-sm font-medium text-zinc-700 transition hover:bg-zinc-50 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  Next
                </button>
              </div>
            </div>

            <.admin_empty_state
              :if={@volunteers == []}
              title="No volunteers found"
              description="Import the spreadsheet or add the first volunteer manually."
            />
          </.admin_panel>
        </div>
      </div>

      <.modal :if={!@access_granted} id="volunteer-access-modal" show>
        <div class="space-y-6">
          <div>
            <h2 class="text-lg font-semibold text-zinc-900">Unlock volunteer list</h2>
            <p class="mt-1 text-sm text-zinc-500">
              Enter your email to receive a six-digit code. The code expires after 2 minutes.
            </p>
          </div>

          <p :if={@access_error} class="rounded-lg bg-rose-50 px-3 py-2 text-sm text-rose-700">
            {@access_error}
          </p>

          <.form
            for={%{}}
            as={:access}
            id="volunteer-access-request-form"
            phx-submit="request_access_code"
            class="space-y-4"
          >
            <.input name="access[email]" value={@access_email} type="email" label="Email" required />

            <.button>
              <.icon name="hero-envelope" class="h-4 w-4" /> Send code
            </.button>
          </.form>

          <.form
            :if={@access_requested}
            for={%{}}
            as={:access}
            id="volunteer-access-verify-form"
            phx-submit="verify_access_code"
            class="space-y-4 border-t border-zinc-100 pt-5"
          >
            <input type="hidden" name="access[email]" value={@access_email} />
            <.input name="access[code]" value="" type="text" label="Access code" required />

            <.button>
              <.icon name="hero-check" class="h-4 w-4" /> Verify and view
            </.button>
          </.form>
        </div>
      </.modal>

      <.modal :if={@show_form} id="volunteer-form-modal" show on_cancel={JS.push("close_form_modal")}>
        <div class="space-y-6">
          <div>
            <h2 class="text-lg font-semibold text-zinc-900">Add or import volunteers</h2>
            <p class="mt-1 text-sm text-zinc-500">
              Add one volunteer manually or upload an .xlsx spreadsheet. Matching emails update existing records instead of creating duplicates.
            </p>
          </div>

          <div class="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
            <section class="rounded-2xl border border-zinc-200 bg-white p-5">
              <h3 class="text-base font-semibold text-zinc-900">Add one volunteer</h3>
              <p class="mt-1 text-sm text-zinc-500">
                Use this for direct admin entry. Email is stored uniquely.
              </p>

              <.simple_form
                for={@form}
                id="volunteer-form"
                phx-change="validate_manual"
                phx-submit="save_manual"
              >
                <div class="grid gap-4 md:grid-cols-2">
                  <.input field={@form[:first_name]} type="text" label="First name" />
                  <.input field={@form[:last_name]} type="text" label="Last name" />
                  <.input field={@form[:email]} type="email" label="Email" required />
                  <.input field={@form[:phone]} type="text" label="Phone" />
                  <.input field={@form[:county]} type="text" label="County" />
                  <.input field={@form[:constituency]} type="text" label="Constituency" />
                  <.input field={@form[:ward]} type="text" label="Ward" />
                  <.input field={@form[:polling_station]} type="text" label="Polling station" />
                  <.input field={@form[:joined_on]} type="date" label="Joined date" />
                </div>

                <.input
                  field={@form[:additional_info]}
                  type="textarea"
                  label="Additional info"
                  rows="4"
                />

                <:actions>
                  <.button>Add volunteer</.button>
                </:actions>
              </.simple_form>
            </section>

            <section class="rounded-2xl border border-zinc-200 bg-zinc-50/70 p-5">
              <h3 class="text-base font-semibold text-zinc-900">Import from Excel</h3>
              <p class="mt-1 text-sm text-zinc-500">
                Upload another volunteer sheet in .xlsx format.
              </p>

              <.form id="volunteer-import-form" for={%{}} phx-submit="import" class="mt-5 space-y-4">
                <label class="block">
                  <span class="mb-2 block text-sm font-medium text-zinc-900">
                    Volunteer spreadsheet
                  </span>
                  <div class="rounded-xl border border-dashed border-zinc-300 bg-white p-4">
                    <label class="flex cursor-pointer flex-col items-center justify-center gap-2 rounded-lg px-4 py-6 text-center text-sm text-zinc-600 transition hover:text-blueink">
                      <.icon name="hero-arrow-up-tray" class="h-5 w-5" />
                      <span class="font-medium">Choose .xlsx file</span>
                      <span class="text-xs text-zinc-400">
                        Existing emails will be updated during import.
                      </span>
                      <.live_file_input upload={@uploads.spreadsheet} class="sr-only" />
                    </label>
                  </div>
                </label>

                <div
                  :for={entry <- @uploads.spreadsheet.entries}
                  class="rounded-lg bg-white px-3 py-2 text-sm text-zinc-700"
                >
                  <div class="flex items-center justify-between gap-4">
                    <span class="truncate">{entry.client_name}</span>
                    <span>{entry.progress}%</span>
                  </div>
                </div>

                <p :for={error <- upload_errors(@uploads.spreadsheet)} class="text-sm text-rose-600">
                  {upload_error_to_string(error)}
                </p>

                <div :for={entry <- @uploads.spreadsheet.entries}>
                  <p
                    :for={error <- upload_errors(@uploads.spreadsheet, entry)}
                    class="text-sm text-rose-600"
                  >
                    {upload_error_to_string(error)}
                  </p>
                </div>

                <div class="flex items-center justify-between gap-3 pt-2">
                  <button
                    type="button"
                    phx-click="close_form_modal"
                    class="rounded-lg px-4 py-2.5 text-sm font-medium text-zinc-600 transition hover:text-zinc-900"
                  >
                    Cancel
                  </button>
                  <.button>Import volunteers</.button>
                </div>
              </.form>
            </section>
          </div>
        </div>
      </.modal>
    </.admin_shell>
    """
  end
end
