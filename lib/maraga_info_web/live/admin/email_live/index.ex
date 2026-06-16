defmodule MaragaInfoWeb.Admin.EmailLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Campaigns
  alias MaragaInfo.Campaigns.CampaignEmail
  alias MaragaInfo.Campaigns.EmailCampaign
  alias Phoenix.LiveView.JS

  @poll_interval 2_000

  @default_attrs %{
    "subject" => "Kenya Cannot Wait. Be at Ufungamano This Tuesday.",
    "preheader" => "Maraga's State of the Nation — Tuesday, June 16 at Ufungamano House.",
    "sender_name" => "David Maraga Campaign",
    "sender_title" => "Ukombozi 2027",
    "body" => """
    Dear {{name}},

    This Tuesday, June 16, former Chief Justice David Maraga will stand before the nation and say what many Kenyans have been waiting to hear.

    His State of the Nation address, "State of the Nation: The Way Forward," brings together moral authorities, opposition leaders, civil society, youth, and professionals for a frank national conversation about where Kenya is, and where it must go.

    The address draws on findings from the Ukatiba Caravan, which engaged citizens across 43 counties earlier this year. Maraga will lay out a three-part national recovery agenda anchored in constitutionalism, human dignity, and economic renewal, and will present his vision for Ukombozi 2027.

    Your voice belongs in that room.

    DATE: Tuesday, June 16, 2026
    TIME: 9:00 AM to 1:00 PM
    VENUE: Ufungamano House, Nairobi

    Come. Be part of the conversation that shapes what comes next.\
    """
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Email broadcasts")
     |> assign(
       :page_subtitle,
       "Design a beautiful email and send it to the whole volunteer database. Delivery runs in the background through Oban with automatic retries."
     )
     |> assign(:recipient_count, Campaigns.recipient_count())
     |> assign(:test_email, "")
     |> assign(:confirm_send, false)
     |> assign(:polling, false)
     |> reset_composer()
     |> load_campaigns()}
  end

  @impl true
  def handle_params(_params, url, socket) do
    {:noreply, assign(socket, :current_path, URI.parse(url).path)}
  end

  ## Events

  @impl true
  def handle_event("validate", %{"email_campaign" => params}, socket) do
    changeset =
      socket.assigns.campaign
      |> Campaigns.change_campaign(params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:draft_params, params)
     |> assign_form(changeset)
     |> refresh_preview(changeset)}
  end

  def handle_event("update_test_email", %{"value" => value}, socket) do
    {:noreply, assign(socket, :test_email, value)}
  end

  def handle_event("save_draft", %{"email_campaign" => params}, socket) do
    case persist(socket.assigns.campaign, params) do
      {:ok, campaign} ->
        {:noreply,
         socket
         |> put_flash(:info, "Draft saved.")
         |> load_into_composer(campaign)
         |> load_campaigns()}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("send_test", _payload, socket) do
    params = socket.assigns.draft_params
    email = String.trim(socket.assigns.test_email)

    cond do
      email == "" ->
        {:noreply, put_flash(socket, :error, "Enter an email address to send a test to.")}

      true ->
        changeset = Campaigns.change_campaign(socket.assigns.campaign, params)
        campaign = Ecto.Changeset.apply_changes(changeset)

        case Campaigns.send_test_email(campaign, email) do
          {:ok, _} ->
            {:noreply, put_flash(socket, :info, "Test email sent to #{email}.")}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Could not send test: #{inspect(reason)}")}
        end
    end
  end

  def handle_event("request_send", _payload, socket) do
    case persist(socket.assigns.campaign, socket.assigns.draft_params) do
      {:ok, campaign} ->
        {:noreply,
         socket
         |> load_into_composer(campaign)
         |> assign(:confirm_send, true)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign_form(changeset)
         |> put_flash(:error, "Fix the highlighted fields before sending.")}
    end
  end

  def handle_event("cancel_send", _params, socket) do
    {:noreply, assign(socket, :confirm_send, false)}
  end

  def handle_event("confirm_send", _params, socket) do
    case Campaigns.send_campaign(socket.assigns.campaign) do
      {:ok, _campaign} ->
        {:noreply,
         socket
         |> assign(:confirm_send, false)
         |> put_flash(:info, "Sending started — delivery is running in the background.")
         |> reset_composer()
         |> load_campaigns()
         |> ensure_polling()}

      {:error, :no_recipients} ->
        {:noreply,
         socket
         |> assign(:confirm_send, false)
         |> put_flash(:error, "There are no volunteers with an email address to send to.")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:confirm_send, false)
         |> put_flash(:error, "Could not start sending: #{inspect(reason)}")}
    end
  end

  def handle_event("new_campaign", _params, socket) do
    {:noreply, reset_composer(socket)}
  end

  def handle_event("edit_campaign", %{"id" => id}, socket) do
    campaign = Campaigns.get_campaign!(id)

    if campaign.status == "draft" do
      {:noreply, load_into_composer(socket, campaign)}
    else
      {:noreply, put_flash(socket, :error, "Only drafts can be edited.")}
    end
  end

  @impl true
  def handle_info(:tick, socket) do
    socket = load_campaigns(socket)

    socket =
      if Enum.any?(socket.assigns.campaigns, &(&1.status == "sending")) do
        schedule_tick()
        socket
      else
        assign(socket, :polling, false)
      end

    {:noreply, socket}
  end

  ## Helpers

  defp persist(%EmailCampaign{id: nil}, params), do: Campaigns.create_campaign(params)

  defp persist(%EmailCampaign{} = campaign, params),
    do: Campaigns.update_campaign(campaign, params)

  defp reset_composer(socket) do
    campaign = %EmailCampaign{}
    changeset = Campaigns.change_campaign(campaign, @default_attrs)

    socket
    |> assign(:campaign, campaign)
    |> assign(:draft_params, @default_attrs)
    |> assign_form(changeset)
    |> refresh_preview(changeset)
  end

  defp load_into_composer(socket, %EmailCampaign{} = campaign) do
    changeset = Campaigns.change_campaign(campaign)

    socket
    |> assign(:campaign, campaign)
    |> assign(:draft_params, campaign_to_params(campaign))
    |> assign_form(changeset)
    |> refresh_preview(changeset)
  end

  defp campaign_to_params(%EmailCampaign{} = campaign) do
    %{
      "subject" => campaign.subject,
      "preheader" => campaign.preheader,
      "body" => campaign.body,
      "sender_name" => campaign.sender_name,
      "sender_title" => campaign.sender_title,
      "reply_to" => campaign.reply_to
    }
  end

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))

  defp refresh_preview(socket, changeset) do
    preview = Ecto.Changeset.apply_changes(changeset) |> preview_defaults()
    assign(socket, :preview_html, CampaignEmail.render_html(preview, %{name: "Jane Mwangi"}))
  end

  defp preview_defaults(%EmailCampaign{} = campaign) do
    %EmailCampaign{
      campaign
      | subject: present(campaign.subject) || "Your subject line",
        body: present(campaign.body) || "Start writing your message…",
        sender_name: present(campaign.sender_name) || "Your name"
    }
  end

  defp load_campaigns(socket) do
    campaigns = Campaigns.list_campaigns()

    live_stats =
      campaigns
      |> Enum.filter(&(&1.status == "sending"))
      |> Map.new(fn c -> {c.id, Campaigns.delivery_stats(c.id)} end)

    socket
    |> assign(:campaigns, campaigns)
    |> assign(:live_stats, live_stats)
  end

  defp ensure_polling(socket) do
    if socket.assigns.polling do
      socket
    else
      if Enum.any?(socket.assigns.campaigns, &(&1.status == "sending")) do
        schedule_tick()
        assign(socket, :polling, true)
      else
        socket
      end
    end
  end

  defp schedule_tick, do: Process.send_after(self(), :tick, @poll_interval)

  defp present(nil), do: nil

  defp present(value) when is_binary(value),
    do: if(String.trim(value) == "", do: nil, else: value)

  defp status_tone("draft"), do: "draft"
  defp status_tone("sending"), do: "neutral"
  defp status_tone("sent"), do: "published"
  defp status_tone(_), do: "neutral"

  defp format_datetime(nil), do: "—"
  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y, %H:%M")

  defp campaign_progress(%EmailCampaign{status: "sending"} = campaign, live_stats) do
    Map.get(live_stats, campaign.id, %{
      sent: campaign.sent_count,
      failed: campaign.failed_count,
      pending: 0,
      total: campaign.recipient_count
    })
  end

  defp campaign_progress(%EmailCampaign{} = campaign, _live_stats) do
    %{
      sent: campaign.sent_count,
      failed: campaign.failed_count,
      pending: 0,
      total: campaign.recipient_count
    }
  end

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
        <button
          type="button"
          phx-click="new_campaign"
          class="inline-flex items-center gap-2 rounded-lg border border-zinc-200 bg-white px-4 py-2.5 text-sm font-semibold text-zinc-700 transition hover:bg-zinc-50"
        >
          <.icon name="hero-document-plus-mini" class="h-4 w-4" /> New email
        </button>
      </:actions>

      <div class="space-y-6">
        <.form
          for={@form}
          id="email-composer"
          phx-change="validate"
          phx-submit="save_draft"
          class="grid gap-6 lg:grid-cols-2"
        >
          <%!-- Composer --%>
          <.admin_panel
            title="Design your email"
            subtitle="Use {{name}} anywhere to drop in each recipient's name. Lines like DATE: / TIME: / VENUE: become a highlighted details card."
          >
            <div class="space-y-4">
              <.input field={@form[:subject]} type="text" label="Subject line" required />
              <.input
                field={@form[:preheader]}
                type="text"
                label="Preview text"
                placeholder="Short summary shown in the inbox preview"
              />

              <.input field={@form[:body]} type="textarea" label="Message" rows="16" required />

              <div class="grid gap-4 sm:grid-cols-2">
                <.input field={@form[:sender_name]} type="text" label="Sign-off name" required />
                <.input field={@form[:sender_title]} type="text" label="Sign-off title" />
              </div>

              <.input
                field={@form[:reply_to]}
                type="email"
                label="Reply-to address"
                placeholder="replies@davidmaraga.info (optional)"
              />

              <div class="flex flex-wrap items-center gap-3 border-t border-zinc-100 pt-4">
                <.button type="submit" phx-disable-with="Saving…">Save draft</.button>
                <button
                  type="button"
                  phx-click="request_send"
                  class="inline-flex items-center gap-2 rounded-lg bg-blueink px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blueink/90"
                >
                  <.icon name="hero-paper-airplane-mini" class="h-4 w-4" />
                  Send to {@recipient_count} volunteers
                </button>
              </div>

              <div class="rounded-xl border border-zinc-200 bg-zinc-50 p-4">
                <p class="text-sm font-medium text-zinc-900">Send yourself a test first</p>
                <div class="mt-2 flex flex-col gap-2 sm:flex-row">
                  <input
                    type="email"
                    name="test_to"
                    value={@test_email}
                    phx-keyup="update_test_email"
                    phx-debounce="200"
                    placeholder="you@example.com"
                    class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                  />
                  <button
                    type="button"
                    phx-click="send_test"
                    class="shrink-0 rounded-lg border border-zinc-300 bg-white px-4 py-2 text-sm font-medium text-zinc-700 transition hover:bg-zinc-50"
                  >
                    Send test
                  </button>
                </div>
              </div>
            </div>
          </.admin_panel>

          <%!-- Live preview --%>
          <.admin_panel title="Live preview" subtitle="Exactly how it lands in the inbox.">
            <iframe
              srcdoc={@preview_html}
              title="Email preview"
              sandbox="allow-same-origin"
              class="h-[680px] w-full rounded-xl border border-zinc-200 bg-white"
            >
            </iframe>
          </.admin_panel>
        </.form>

        <%!-- History --%>
        <.admin_panel title="Broadcasts" subtitle="Drafts, in-flight sends, and everything delivered.">
          <div :if={@campaigns != []} class="divide-y divide-zinc-100">
            <div
              :for={campaign <- @campaigns}
              class="flex flex-col gap-3 py-4 first:pt-0 last:pb-0 sm:flex-row sm:items-center sm:justify-between"
            >
              <div class="min-w-0">
                <div class="flex items-center gap-2">
                  <p class="truncate font-medium text-zinc-900">{campaign.subject}</p>
                  <.admin_badge tone={status_tone(campaign.status)} label={campaign.status} />
                </div>
                <p class="mt-0.5 text-sm text-zinc-500">
                  <%= case campaign.status do %>
                    <% "draft" -> %>
                      Draft &middot; updated {format_datetime(campaign.updated_at)}
                    <% "sending" -> %>
                      {(stats = campaign_progress(campaign, @live_stats)) &&
                        "Sending… #{stats.sent}/#{stats.total} delivered" <>
                          if(stats.failed > 0, do: " · #{stats.failed} failed", else: "")}
                    <% _ -> %>
                      {(stats = campaign_progress(campaign, @live_stats)) &&
                        "Sent to #{stats.sent} of #{stats.total}" <>
                          if(stats.failed > 0, do: " · #{stats.failed} failed", else: "")} &middot; {format_datetime(
                        campaign.sent_at
                      )}
                  <% end %>
                </p>

                <div
                  :if={campaign.status == "sending"}
                  class="mt-2 h-1.5 w-full max-w-xs overflow-hidden rounded-full bg-zinc-100"
                >
                  <% stats = campaign_progress(campaign, @live_stats) %>
                  <div
                    class="h-full rounded-full bg-blueink transition-all"
                    style={"width: #{progress_pct(stats)}%"}
                  >
                  </div>
                </div>
              </div>

              <div class="flex shrink-0 items-center gap-3">
                <button
                  :if={campaign.status == "draft"}
                  type="button"
                  phx-click="edit_campaign"
                  phx-value-id={campaign.id}
                  class="text-sm font-medium text-blueink hover:underline"
                >
                  Edit
                </button>
              </div>
            </div>
          </div>

          <.admin_empty_state
            :if={@campaigns == []}
            title="No broadcasts yet"
            description="Design your first email above, send yourself a test, then send it to the volunteer database."
          />
        </.admin_panel>
      </div>

      <.modal :if={@confirm_send} id="confirm-send-modal" show on_cancel={JS.push("cancel_send")}>
        <div class="space-y-5">
          <div class="flex items-start gap-3">
            <div class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-blueink/10 text-blueink">
              <.icon name="hero-paper-airplane" class="h-5 w-5" />
            </div>
            <div>
              <h2 class="text-lg font-semibold text-zinc-900">Send this email now?</h2>
              <p class="mt-1 text-sm text-zinc-500">
                This will queue <span class="font-semibold text-zinc-900">{@recipient_count}</span>
                emails to every volunteer with an email address. Delivery runs in the background and can't be undone.
              </p>
            </div>
          </div>

          <div class="rounded-lg border border-zinc-200 bg-zinc-50 px-4 py-3">
            <p class="text-xs uppercase tracking-wide text-zinc-400">Subject</p>
            <p class="mt-0.5 text-sm font-medium text-zinc-900">{@campaign.subject}</p>
          </div>

          <div class="flex items-center justify-end gap-3">
            <button
              type="button"
              phx-click="cancel_send"
              class="rounded-lg px-4 py-2.5 text-sm font-medium text-zinc-600 transition hover:text-zinc-900"
            >
              Cancel
            </button>
            <button
              type="button"
              phx-click="confirm_send"
              phx-disable-with="Queuing…"
              class="inline-flex items-center gap-2 rounded-lg bg-blueink px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blueink/90"
            >
              Yes, send to {@recipient_count} volunteers
            </button>
          </div>
        </div>
      </.modal>
    </.admin_shell>
    """
  end

  defp progress_pct(%{total: 0}), do: 0

  defp progress_pct(%{sent: sent, failed: failed, total: total}) do
    round((sent + failed) / total * 100)
  end
end
