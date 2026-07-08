defmodule MaragaInfoWeb.Admin.EmailLive.Analytics do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Campaigns
  alias MaragaInfo.Campaigns.EmailCampaign
  alias MaragaInfo.Campaigns.EmailDelivery

  @page_size 25
  @utc_plus_3_offset 3 * 60 * 60

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Email analytics")
     |> assign(:page_subtitle, "Campaign delivery analytics in UTC+3.")
     |> assign(:campaign, nil)
     |> assign(:stats, %{sent: 0, failed: 0, pending: 0, total: 0})
     |> assign(:variant_stats, %{})
     |> assign(:overview, %{first_sent_at: nil, last_sent_at: nil, last_updated_at: nil})
     |> assign(:deliveries, [])
     |> assign(:query, "")
     |> assign(:status_filter, "all")
     |> assign(:variant_filter, "all")
     |> assign(:page, 1)
     |> assign(:per_page, @page_size)
     |> assign(:total_entries, 0)
     |> assign(:total_pages, 1)
     |> assign(:page_numbers, [1])
     |> assign(:first_entry, 0)
     |> assign(:last_entry, 0)}
  end

  @impl true
  def handle_params(%{"id" => id}, url, socket) do
    campaign = Campaigns.get_campaign!(id)

    {:noreply,
     socket
     |> assign(:current_path, URI.parse(url).path)
     |> assign(:campaign, campaign)
     |> assign(:page_title, "#{campaign.subject} analytics")
     |> assign(
       :page_subtitle,
       "Delivery status, recipient history, and send timing for this campaign in UTC+3."
     )
     |> load_data()}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply, socket |> assign(:query, query) |> assign(:page, 1) |> load_data()}
  end

  def handle_event("filter", params, socket) do
    status_filter = Map.get(params, "status", socket.assigns.status_filter)
    variant_filter = Map.get(params, "variant", socket.assigns.variant_filter)

    {:noreply,
     socket
     |> assign(:status_filter, normalize_status_filter(status_filter))
     |> assign(:variant_filter, normalize_variant_filter(variant_filter))
     |> assign(:page, 1)
     |> load_data()}
  end

  def handle_event("prev_page", _params, socket) do
    {:noreply, socket |> update(:page, &max(&1 - 1, 1)) |> load_data()}
  end

  def handle_event("next_page", _params, socket) do
    {:noreply, socket |> update(:page, &min(&1 + 1, socket.assigns.total_pages)) |> load_data()}
  end

  def handle_event("go_page", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, parse_page(page)) |> load_data()}
  end

  defp load_data(%{assigns: %{campaign: %EmailCampaign{} = campaign}} = socket) do
    filters = delivery_filters(socket)
    total_entries = Campaigns.count_deliveries(campaign.id, filters)
    total_pages = total_pages(total_entries, socket.assigns.per_page)
    page = socket.assigns.page |> max(1) |> min(total_pages)
    offset = (page - 1) * socket.assigns.per_page

    socket
    |> assign(:stats, Campaigns.delivery_stats(campaign.id))
    |> assign(:variant_stats, Campaigns.variant_stats(campaign.id))
    |> assign(:overview, Campaigns.delivery_overview(campaign.id))
    |> assign(:page, page)
    |> assign(:total_entries, total_entries)
    |> assign(:total_pages, total_pages)
    |> assign(:page_numbers, page_numbers(page, total_pages))
    |> assign(:first_entry, first_entry(total_entries, offset))
    |> assign(:last_entry, last_entry(total_entries, offset, socket.assigns.per_page))
    |> assign(
      :deliveries,
      Campaigns.list_deliveries(campaign.id,
        filters ++ [limit: socket.assigns.per_page, offset: offset]
      )
    )
  end

  defp load_data(socket), do: socket

  defp delivery_filters(socket) do
    [
      query: socket.assigns.query,
      status: socket.assigns.status_filter,
      variant: socket.assigns.variant_filter
    ]
  end

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

  defp last_entry(0, _offset, _per_page), do: 0
  defp last_entry(total_entries, offset, per_page), do: min(offset + per_page, total_entries)

  defp parse_page(page) do
    page
    |> to_string()
    |> Integer.parse()
    |> case do
      {value, _rest} -> max(value, 1)
      :error -> 1
    end
  end

  defp normalize_status_filter(status) when status in ~w(all pending sent failed), do: status
  defp normalize_status_filter(_status), do: "all"

  defp normalize_variant_filter(variant) when variant in ~w(all A B), do: variant
  defp normalize_variant_filter(_variant), do: "all"

  defp status_tone("draft"), do: "draft"
  defp status_tone("sending"), do: "neutral"
  defp status_tone("sent"), do: "published"
  defp status_tone("failed"), do: "draft"
  defp status_tone("pending"), do: "neutral"
  defp status_tone(_), do: "neutral"

  defp success_rate(%{total: 0}), do: "0%"

  defp success_rate(%{sent: sent, total: total}) do
    "#{round(sent / total * 100)}%"
  end

  defp format_datetime(value) do
    case value do
      %DateTime{} = dt ->
        dt
        |> DateTime.add(@utc_plus_3_offset, :second)
        |> Calendar.strftime("%d %b %Y, %H:%M")

      _ ->
        "—"
    end
  end

  defp format_datetime_with_zone(nil), do: "—"
  defp format_datetime_with_zone(%DateTime{} = dt), do: "#{format_datetime(dt)} UTC+3"

  defp duration_label(%{first_sent_at: nil}), do: "Waiting for the first successful send."
  defp duration_label(%{first_sent_at: _first, last_sent_at: nil}), do: "Waiting for send timestamps."

  defp duration_label(%{first_sent_at: first_sent_at, last_sent_at: last_sent_at}) do
    seconds = DateTime.diff(last_sent_at, first_sent_at, :second)

    cond do
      seconds < 60 -> "#{seconds}s between first and last send"
      seconds < 3600 -> "#{div(seconds, 60)}m between first and last send"
      true -> "#{Float.round(seconds / 3600, 1)}h between first and last send"
    end
  end

  defp recipient_name(%EmailDelivery{name: name}) when is_binary(name) and name != "", do: name
  defp recipient_name(_delivery), do: "—"

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
          navigate={~p"/admin/emails/#{@campaign.id}"}
          class="inline-flex items-center gap-2 rounded-lg border border-zinc-200 bg-white px-4 py-2.5 text-sm font-semibold text-zinc-700 transition hover:bg-zinc-50"
        >
          <.icon name="hero-pencil-square-mini" class="h-4 w-4" /> Edit campaign
        </.link>
        <.link
          navigate={~p"/admin/emails"}
          class="inline-flex items-center gap-2 rounded-lg border border-zinc-200 bg-white px-4 py-2.5 text-sm font-semibold text-zinc-700 transition hover:bg-zinc-50"
        >
          <.icon name="hero-arrow-left-mini" class="h-4 w-4" /> All broadcasts
        </.link>
      </:actions>

      <div class="space-y-6">
        <.admin_panel title="Campaign overview" subtitle="Everything on this screen is displayed in UTC+3.">
          <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <.admin_stat title="Audience" value={Integer.to_string(@stats.total)} hint="Recipient rows captured for this send" />
            <.admin_stat title="Delivered" value={Integer.to_string(@stats.sent)} hint={"Success rate #{@stats |> success_rate()}"} tone="accent" />
            <.admin_stat title="Failed" value={Integer.to_string(@stats.failed)} hint="Rows that exhausted delivery attempts" />
            <.admin_stat title="Pending" value={Integer.to_string(@stats.pending)} hint="Still waiting in the queue" />
          </div>

          <div class="mt-5 grid gap-4 lg:grid-cols-3">
            <div class="rounded-xl border border-zinc-200 bg-zinc-50 p-4">
              <p class="text-xs font-semibold uppercase tracking-wide text-zinc-400">Campaign status</p>
              <div class="mt-2 flex items-center gap-2">
                <.admin_badge tone={status_tone(@campaign.status)} label={@campaign.status} />
                <.admin_badge :if={@campaign.ab_test} tone="neutral" label="A/B test" />
              </div>
              <p class="mt-3 text-sm text-zinc-600">
                Completed at {format_datetime_with_zone(@campaign.sent_at)}
              </p>
            </div>

            <div class="rounded-xl border border-zinc-200 bg-zinc-50 p-4">
              <p class="text-xs font-semibold uppercase tracking-wide text-zinc-400">Send window</p>
              <p class="mt-2 text-sm font-medium text-zinc-900">
                First success: {format_datetime_with_zone(@overview.first_sent_at)}
              </p>
              <p class="mt-1 text-sm font-medium text-zinc-900">
                Last success: {format_datetime_with_zone(@overview.last_sent_at)}
              </p>
              <p class="mt-3 text-sm text-zinc-600">{duration_label(@overview)}</p>
            </div>

            <div class="rounded-xl border border-zinc-200 bg-zinc-50 p-4">
              <p class="text-xs font-semibold uppercase tracking-wide text-zinc-400">Latest activity</p>
              <p class="mt-2 text-sm font-medium text-zinc-900">
                Last delivery update: {format_datetime_with_zone(@overview.last_updated_at)}
              </p>
              <div :if={@campaign.ab_test} class="mt-3 flex flex-wrap gap-2">
                <span
                  :for={variant <- EmailCampaign.variants()}
                  :if={vstats = Map.get(@variant_stats, variant)}
                  class="inline-flex items-center gap-1.5 rounded-md bg-white px-2.5 py-1 text-xs text-zinc-600 ring-1 ring-inset ring-zinc-200"
                >
                  <span class="font-semibold text-zinc-900">{variant}</span>
                  {vstats.sent}/{vstats.total} sent
                  <span :if={vstats.failed > 0}>· {vstats.failed} failed</span>
                </span>
              </div>
            </div>
          </div>
        </.admin_panel>

        <.admin_panel title="Recipient deliveries" subtitle="Search, filter, and inspect each recipient row that was queued for this campaign.">
          <div class="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
            <form phx-submit="search" class="flex w-full max-w-xl gap-2">
              <input
                type="text"
                name="q"
                value={@query}
                placeholder="Search by email, name, or error"
                class="w-full rounded-lg border border-zinc-300 px-3 py-2.5 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
              />
              <button
                type="submit"
                class="rounded-lg bg-blueink px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blueink/90"
              >
                Search
              </button>
            </form>

            <form phx-change="filter" class="flex flex-wrap items-center gap-2">
              <select
                name="status"
                class="rounded-lg border border-zinc-300 px-3 py-2.5 text-sm text-zinc-900 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
              >
                <option value="all" selected={@status_filter == "all"}>All statuses</option>
                <option value="sent" selected={@status_filter == "sent"}>Sent</option>
                <option value="pending" selected={@status_filter == "pending"}>Pending</option>
                <option value="failed" selected={@status_filter == "failed"}>Failed</option>
              </select>
              <select
                name="variant"
                class="rounded-lg border border-zinc-300 px-3 py-2.5 text-sm text-zinc-900 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
              >
                <option value="all" selected={@variant_filter == "all"}>All variants</option>
                <option value="A" selected={@variant_filter == "A"}>Variant A</option>
                <option :if={@campaign.ab_test} value="B" selected={@variant_filter == "B"}>Variant B</option>
              </select>
            </form>
          </div>

          <div class="mt-4 flex items-center justify-between text-sm text-zinc-500">
            <p>
              Showing {@first_entry}-{@last_entry} of {@total_entries} deliveries
            </p>
            <p>Times shown in UTC+3</p>
          </div>

          <div :if={@deliveries != []} class="mt-4 overflow-hidden rounded-xl border border-zinc-200">
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-zinc-200 text-sm">
                <thead class="bg-zinc-50 text-left text-xs uppercase tracking-wide text-zinc-500">
                  <tr>
                    <th class="px-4 py-3 font-semibold">Recipient</th>
                    <th class="px-4 py-3 font-semibold">Variant</th>
                    <th class="px-4 py-3 font-semibold">Status</th>
                    <th class="px-4 py-3 font-semibold">Sent at</th>
                    <th class="px-4 py-3 font-semibold">Updated at</th>
                    <th class="px-4 py-3 font-semibold">Error</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-zinc-100 bg-white">
                  <tr :for={delivery <- @deliveries}>
                    <td class="px-4 py-3 align-top">
                      <p class="font-medium text-zinc-900">{delivery.email}</p>
                      <p class="mt-0.5 text-zinc-500">{recipient_name(delivery)}</p>
                    </td>
                    <td class="px-4 py-3 align-top text-zinc-700">{delivery.variant}</td>
                    <td class="px-4 py-3 align-top">
                      <.admin_badge tone={status_tone(delivery.status)} label={delivery.status} />
                    </td>
                    <td class="px-4 py-3 align-top text-zinc-700">
                      {format_datetime_with_zone(delivery.sent_at)}
                    </td>
                    <td class="px-4 py-3 align-top text-zinc-700">
                      {format_datetime_with_zone(delivery.updated_at)}
                    </td>
                    <td class="px-4 py-3 align-top text-zinc-500">
                      {delivery.error || "—"}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <.admin_empty_state
            :if={@deliveries == []}
            title="No delivery rows match these filters"
            description="Try clearing the search or filters, or send the campaign first if it is still a draft."
          />

          <div :if={@total_pages > 1} class="mt-4 flex flex-wrap items-center justify-between gap-3">
            <p class="text-sm text-zinc-500">
              Page {@page} of {@total_pages}
            </p>
            <div class="flex flex-wrap items-center gap-2">
              <button
                type="button"
                phx-click="prev_page"
                disabled={@page <= 1}
                class="rounded-lg border border-zinc-200 bg-white px-3 py-2 text-sm font-medium text-zinc-700 transition hover:bg-zinc-50 disabled:cursor-not-allowed disabled:opacity-40"
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
                  page_number == @page && "bg-blueink text-white",
                  page_number != @page &&
                    "border border-zinc-200 bg-white text-zinc-700 hover:bg-zinc-50"
                ]}
              >
                {page_number}
              </button>
              <button
                type="button"
                phx-click="next_page"
                disabled={@page >= @total_pages}
                class="rounded-lg border border-zinc-200 bg-white px-3 py-2 text-sm font-medium text-zinc-700 transition hover:bg-zinc-50 disabled:cursor-not-allowed disabled:opacity-40"
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
