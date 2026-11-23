defmodule MaragaInfoWeb.Admin.VoterDriveLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.VoterDrive
  alias MaragaInfo.VoterDrive.Registration

  @page_size 25
  @interests [
    "Fund Raising / Donating",
    "Civic Education",
    "Community Organization",
    "Issue Based Organizing",
    "Digital Organizing",
    "Volunteer Recruitment & Training"
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Voter Drive")
     |> assign(
       :page_subtitle,
       "Search voter-drive registrations collected online and from the legacy campaign workbook."
     )
     |> assign(:filters, default_filters())
     |> assign(:counties, VoterDrive.list_counties())
     |> assign(:interests, @interests)
     |> assign(:page, 1)
     |> load_data()}
  end

  @impl true
  def handle_params(_params, url, socket) do
    {:noreply, assign(socket, :current_path, URI.parse(url).path)}
  end

  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    {:noreply,
     socket
     |> assign(filters: Map.merge(default_filters(), filters), page: 1)
     |> load_data()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, socket |> assign(filters: default_filters(), page: 1) |> load_data()}
  end

  def handle_event("previous", _params, socket) do
    {:noreply, socket |> update(:page, &max(&1 - 1, 1)) |> load_data()}
  end

  def handle_event("next", _params, socket) do
    {:noreply, socket |> update(:page, &min(&1 + 1, socket.assigns.total_pages)) |> load_data()}
  end

  defp load_data(socket) do
    options = filter_options(socket.assigns.filters)
    total = VoterDrive.count_registrations(options)
    total_pages = max(ceil(total / @page_size), 1)
    page = min(socket.assigns.page, total_pages)
    offset = (page - 1) * @page_size

    assign(socket,
      stats: VoterDrive.registration_stats(),
      registrations:
        VoterDrive.list_registrations(options ++ [limit: @page_size, offset: offset]),
      page: page,
      total: total,
      total_pages: total_pages,
      first: if(total == 0, do: 0, else: offset + 1),
      last: min(offset + @page_size, total)
    )
  end

  defp default_filters do
    %{
      "query" => "",
      "county" => "",
      "interest" => "",
      "source" => "",
      "polling_station" => ""
    }
  end

  defp filter_options(filters) do
    [
      query: filters["query"],
      county: filters["county"],
      interest: filters["interest"],
      source: filters["source"],
      polling_station: filters["polling_station"]
    ]
  end

  defp filters_active?(filters), do: Enum.any?(filters, fn {_key, value} -> value != "" end)

  defp name(%Registration{} = registration) do
    [registration.first_name, registration.last_name]
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.join(" ")
    |> case do
      "" -> registration.email
      value -> value
    end
  end

  defp location(%Registration{} = registration) do
    [registration.county, registration.constituency, registration.ward]
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.join(" · ")
  end

  defp format_date(nil), do: "—"
  defp format_date(date), do: Calendar.strftime(date, "%d %b %Y")

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell
      page_title={@page_title}
      page_subtitle={@page_subtitle}
      current_user={@current_user}
      current_path={@current_path}
    >
      <div class="space-y-6">
        <section class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <.admin_stat
            title="Registrations"
            value={Integer.to_string(@stats.total)}
            hint="All voter-drive records"
          />
          <.admin_stat
            title="Counties"
            value={Integer.to_string(@stats.counties)}
            hint="Counties represented"
            tone="accent"
          />
          <.admin_stat
            title="Polling station"
            value={Integer.to_string(@stats.with_polling_station)}
            hint="Station captured"
          />
          <.admin_stat
            title="Website"
            value={Integer.to_string(@stats.website)}
            hint="Submitted on this site"
          />
        </section>

        <.admin_panel
          title="Voter-drive registrations"
          subtitle="Personal details are visible only to authenticated administrators."
        >
          <form phx-change="filter" class="mb-5 grid gap-3 md:grid-cols-2 xl:grid-cols-6">
            <div class="relative md:col-span-2">
              <.icon
                name="hero-magnifying-glass"
                class="pointer-events-none absolute left-3 top-3 h-5 w-5 text-zinc-400"
              />
              <input
                type="search"
                name="filters[query]"
                value={@filters["query"]}
                placeholder="Search name, email, phone or location"
                phx-debounce="300"
                class="w-full rounded-lg border-zinc-300 py-2.5 pl-10 pr-4 text-sm focus:border-blueink focus:ring-blueink"
              />
            </div>
            <select
              name="filters[county]"
              class="rounded-lg border-zinc-300 text-sm focus:border-blueink focus:ring-blueink"
            >
              <option value="">All counties</option>
              <option
                :for={county <- @counties}
                value={county}
                selected={@filters["county"] == county}
              >
                {county}
              </option>
            </select>
            <select
              name="filters[interest]"
              class="rounded-lg border-zinc-300 text-sm focus:border-blueink focus:ring-blueink"
            >
              <option value="">All interests</option>
              <option
                :for={interest <- @interests}
                value={interest}
                selected={@filters["interest"] == interest}
              >
                {interest}
              </option>
            </select>
            <select
              name="filters[source]"
              class="rounded-lg border-zinc-300 text-sm focus:border-blueink focus:ring-blueink"
            >
              <option value="">All sources</option>
              <option value="website" selected={@filters["source"] == "website"}>Website</option>
              <option value="imported" selected={@filters["source"] == "imported"}>
                Imported workbook
              </option>
            </select>
            <select
              name="filters[polling_station]"
              class="rounded-lg border-zinc-300 text-sm focus:border-blueink focus:ring-blueink"
            >
              <option value="">Any polling station</option>
              <option value="with" selected={@filters["polling_station"] == "with"}>
                Station provided
              </option>
              <option value="without" selected={@filters["polling_station"] == "without"}>
                Station missing
              </option>
            </select>
          </form>

          <div
            :if={filters_active?(@filters)}
            class="mb-5 flex items-center justify-between rounded-lg bg-blueink/5 px-4 py-3"
          >
            <p class="text-sm text-blueink">Filters applied · {@total} matching registrations</p>
            <button
              type="button"
              phx-click="clear_filters"
              class="text-sm font-semibold text-crimson hover:underline"
            >
              Clear filters
            </button>
          </div>

          <div :if={@registrations != []} class="overflow-x-auto">
            <table class="min-w-full divide-y divide-zinc-200 text-sm">
              <thead class="bg-zinc-50 text-left text-xs uppercase tracking-wide text-zinc-500">
                <tr>
                  <th class="px-3 py-3 font-medium">Person</th>
                  <th class="px-3 py-3 font-medium">Contact</th>
                  <th class="px-3 py-3 font-medium">Location</th>
                  <th class="px-3 py-3 font-medium">Interests</th>
                  <th class="px-3 py-3 font-medium">Registered</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-zinc-100">
                <tr :for={registration <- @registrations}>
                  <td class="px-3 py-4 align-top font-semibold text-zinc-900">
                    {name(registration)}
                  </td>
                  <td class="px-3 py-4 align-top text-zinc-600">
                    <div>{registration.email}</div>
                    <div>{registration.phone || "—"}</div>
                  </td>
                  <td class="px-3 py-4 align-top text-zinc-600">{location(registration)}</td>
                  <td class="max-w-xs px-3 py-4 align-top text-zinc-600">
                    {Enum.join(registration.interests, ", ")}
                  </td>
                  <td class="whitespace-nowrap px-3 py-4 align-top text-zinc-600">
                    {format_date(registration.registered_on)}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <.admin_empty_state
            :if={@registrations == []}
            title="No registrations found"
            description="Try a different search or wait for the first voter-drive submission."
          />

          <div
            :if={@total > 0}
            class="mt-5 flex flex-col gap-3 border-t border-zinc-100 pt-4 sm:flex-row sm:items-center sm:justify-between"
          >
            <p class="text-sm text-zinc-500">Showing {@first}–{@last} of {@total}</p>
            <div class="flex items-center gap-2">
              <button
                type="button"
                phx-click="previous"
                disabled={@page == 1}
                class="rounded-lg border border-zinc-200 px-3 py-2 text-sm disabled:opacity-40"
              >
                Previous
              </button>
              <span class="text-sm text-zinc-600">Page {@page} of {@total_pages}</span>
              <button
                type="button"
                phx-click="next"
                disabled={@page == @total_pages}
                class="rounded-lg border border-zinc-200 px-3 py-2 text-sm disabled:opacity-40"
              >
                Next
              </button>
            </div>
          </div>
        </.admin_panel>
      </div>
    </.admin_shell>
    """
  end
end
