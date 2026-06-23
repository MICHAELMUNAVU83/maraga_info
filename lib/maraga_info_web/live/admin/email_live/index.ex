defmodule MaragaInfoWeb.Admin.EmailLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Campaigns
  alias MaragaInfo.Campaigns.CampaignEmail
  alias MaragaInfo.Campaigns.EmailCampaign
  alias Phoenix.LiveView.JS

  @poll_interval 2_000

  @default_body """
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    </head>
    <body style="margin:0; padding:0; background-color:#f0f4ff; font-family:Helvetica, Arial, sans-serif; color:#222222;">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f0f4ff;">
        <tr>
          <td align="center" style="padding:32px 16px;">
            <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="width:600px; max-width:600px; background-color:#ffffff; border-radius:16px; overflow:hidden;">
              <tr>
                <td style="background-color:#32673B; padding:28px 40px;" align="center">
                  <span style="color:#ffffff; font-size:24px; font-weight:700;">David Maraga</span>
                </td>
              </tr>
              <tr>
                <td style="height:4px; background-color:#CEB04E; line-height:4px; font-size:4px;">&nbsp;</td>
              </tr>
              <tr>
                <td style="padding:40px; font-size:16px; line-height:1.7;">
                  <h1 style="margin:0 0 16px 0; font-size:24px; color:#32673B;">Kenya Cannot Wait</h1>
                  <p style="margin:0 0 18px 0;">Dear {{name}},</p>
                  <p style="margin:0 0 18px 0;">
                    Write your message here. Use <strong>{{name}}</strong> or
                    {{first_name}} anywhere to greet each volunteer personally.
                  </p>
                  <p style="margin:24px 0 0 0;">Warm regards,<br /><strong>David Maraga Campaign</strong></p>
                </td>
              </tr>
              <tr>
                <td style="background-color:#0f172a; padding:24px 40px; color:#94a3b8; font-size:12px; line-height:1.6;">
                  You are receiving this because you joined the movement.<br />
                  Constitutionalism &middot; Human dignity &middot; Economic renewal
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
  </html>
  """

  @default_body_b String.replace(
                    @default_body,
                    "Kenya Cannot Wait",
                    "It's Time. Stand With Maraga."
                  )

  @default_attrs %{
    "subject" => "Kenya Cannot Wait. Be at Ufungamano This Tuesday.",
    "preheader" => "Maraga's State of the Nation — Tuesday, June 16 at Ufungamano House.",
    "sender_name" => "David Maraga Campaign",
    "sender_title" => "Ukombozi 2027",
    "body" => @default_body,
    "ab_test" => "false",
    "subject_b" => "It's Time. Stand With Maraga This Tuesday.",
    "sender_name_b" => "Team Maraga",
    "body_b" => @default_body_b
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Email broadcasts")
     |> assign(
       :page_subtitle,
       "Design an HTML email and send it to the whole volunteer database. Run an A/B test to split the list between two versions. Delivery runs in the background through Oban with automatic retries."
     )
     |> assign(:recipient_count, Campaigns.recipient_count())
     |> assign(:test_email, "")
     |> assign(:preview_variant, "A")
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

  def handle_event("preview_variant", %{"variant" => variant}, socket)
      when variant in ~w(A B) do
    changeset = Campaigns.change_campaign(socket.assigns.campaign, socket.assigns.draft_params)

    {:noreply,
     socket
     |> assign(:preview_variant, variant)
     |> refresh_preview(changeset)}
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
    variant = socket.assigns.preview_variant

    cond do
      email == "" ->
        {:noreply, put_flash(socket, :error, "Enter an email address to send a test to.")}

      true ->
        changeset = Campaigns.change_campaign(socket.assigns.campaign, params)
        campaign = Ecto.Changeset.apply_changes(changeset)

        case Campaigns.send_test_email(campaign, email, variant) do
          {:ok, _} ->
            {:noreply,
             put_flash(socket, :info, "Test of variant #{variant} sent to #{email}.")}

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
    |> assign(:preview_variant, "A")
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
      "reply_to" => campaign.reply_to,
      "ab_test" => to_string(campaign.ab_test),
      "subject_b" => campaign.subject_b,
      "sender_name_b" => campaign.sender_name_b,
      "body_b" => campaign.body_b
    }
  end

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))

  defp refresh_preview(socket, changeset) do
    campaign = Ecto.Changeset.apply_changes(changeset) |> preview_defaults()
    variant = effective_preview_variant(socket, campaign)
    content = CampaignEmail.variant_content(campaign, variant)
    html = CampaignEmail.render_html(content, %{name: "Jane Mwangi"})

    socket
    |> assign(:preview_variant, variant)
    |> assign(:preview_html, html)
  end

  # A/B preview only makes sense while A/B testing is on; otherwise pin to A.
  defp effective_preview_variant(socket, %EmailCampaign{ab_test: true}),
    do: socket.assigns.preview_variant

  defp effective_preview_variant(_socket, _campaign), do: "A"

  defp preview_defaults(%EmailCampaign{} = campaign) do
    %EmailCampaign{
      campaign
      | subject: present(campaign.subject) || "Your subject line",
        body: present(campaign.body) || placeholder_body("Start writing your HTML email…"),
        sender_name: present(campaign.sender_name) || "Your name",
        subject_b: present(campaign.subject_b) || "Variant B subject line",
        body_b: present(campaign.body_b) || placeholder_body("Variant B — start writing…"),
        sender_name_b: present(campaign.sender_name_b) || "Your name"
    }
  end

  defp placeholder_body(text) do
    ~s(<div style="font-family:Helvetica,Arial,sans-serif; color:#94a3b8; padding:40px; text-align:center;">#{text}</div>)
  end

  defp load_campaigns(socket) do
    campaigns = Campaigns.list_campaigns()

    live_stats =
      campaigns
      |> Enum.filter(&(&1.status == "sending"))
      |> Map.new(fn c -> {c.id, Campaigns.delivery_stats(c.id)} end)

    variant_stats =
      campaigns
      |> Enum.filter(& &1.ab_test)
      |> Map.new(fn c -> {c.id, Campaigns.variant_stats(c.id)} end)

    socket
    |> assign(:campaigns, campaigns)
    |> assign(:live_stats, live_stats)
    |> assign(:variant_stats, variant_stats)
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
            subtitle="Paste a complete HTML email. Use {{name}} or {{first_name}} anywhere to greet each recipient."
          >
            <div class="space-y-4">
              <.input field={@form[:subject]} type="text" label="Subject line" required />
              <.input
                field={@form[:preheader]}
                type="text"
                label="Preview text"
                placeholder="Short summary shown in the inbox preview"
              />

              <.input field={@form[:sender_name]} type="text" label="Sender name (From)" required />

              <.input
                field={@form[:body]}
                type="textarea"
                label="HTML email body"
                rows="16"
                required
              />

              <%!-- A/B testing --%>
              <div class="rounded-xl border border-zinc-200 bg-zinc-50 p-4">
                <.input
                  field={@form[:ab_test]}
                  type="checkbox"
                  label="Run an A/B test (split the list evenly between two versions)"
                />

                <div :if={@form[:ab_test].value in [true, "true"]} class="mt-4 space-y-4 border-t border-zinc-200 pt-4">
                  <p class="text-xs text-zinc-500">
                    Variant B goes to half the volunteers, variant A to the other half.
                  </p>
                  <.input field={@form[:subject_b]} type="text" label="Variant B — subject line" />
                  <.input field={@form[:sender_name_b]} type="text" label="Variant B — sender name" />
                  <.input
                    field={@form[:body_b]}
                    type="textarea"
                    label="Variant B — HTML email body"
                    rows="12"
                  />
                </div>
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
                <p class="text-sm font-medium text-zinc-900">
                  Send yourself a test first
                  <span class="text-zinc-500">(variant {@preview_variant})</span>
                </p>
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
            <:actions>
              <div
                :if={@form[:ab_test].value in [true, "true"]}
                class="inline-flex rounded-lg border border-zinc-200 bg-zinc-100 p-0.5"
              >
                <button
                  :for={variant <- ~w(A B)}
                  type="button"
                  phx-click="preview_variant"
                  phx-value-variant={variant}
                  class={[
                    "rounded-md px-3 py-1 text-xs font-semibold transition",
                    @preview_variant == variant && "bg-white text-zinc-900 shadow-sm",
                    @preview_variant != variant && "text-zinc-500 hover:text-zinc-700"
                  ]}
                >
                  Variant {variant}
                </button>
              </div>
            </:actions>
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
              class="flex flex-col gap-3 py-4 first:pt-0 last:pb-0 sm:flex-row sm:items-start sm:justify-between"
            >
              <div class="min-w-0">
                <div class="flex flex-wrap items-center gap-2">
                  <p class="truncate font-medium text-zinc-900">{campaign.subject}</p>
                  <.admin_badge tone={status_tone(campaign.status)} label={campaign.status} />
                  <.admin_badge :if={campaign.ab_test} tone="neutral" label="A/B" />
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

                <%!-- Per-variant breakdown for A/B campaigns --%>
                <div
                  :if={campaign.ab_test and campaign.status != "draft"}
                  class="mt-2 flex flex-wrap gap-2"
                >
                  <span
                    :for={variant <- ~w(A B)}
                    :if={vstats = Map.get(Map.get(@variant_stats, campaign.id, %{}), variant)}
                    class="inline-flex items-center gap-1.5 rounded-md bg-zinc-100 px-2 py-1 text-xs text-zinc-600"
                  >
                    <span class="font-semibold text-zinc-900">{variant}</span>
                    {vstats.sent}/{vstats.total} sent<%= if vstats.failed > 0,
                      do: " · #{vstats.failed} failed" %>
                  </span>
                </div>

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
                emails to every volunteer with an email address.<span :if={@campaign.ab_test}>
                  The list is split evenly between variant A and variant B.</span>
                Delivery runs in the background and can't be undone.
              </p>
            </div>
          </div>

          <div class="rounded-lg border border-zinc-200 bg-zinc-50 px-4 py-3">
            <p class="text-xs uppercase tracking-wide text-zinc-400">Subject</p>
            <p class="mt-0.5 text-sm font-medium text-zinc-900">{@campaign.subject}</p>
            <p :if={@campaign.ab_test} class="mt-2 text-xs uppercase tracking-wide text-zinc-400">
              Variant B subject
            </p>
            <p :if={@campaign.ab_test} class="mt-0.5 text-sm font-medium text-zinc-900">
              {@campaign.subject_b}
            </p>
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
