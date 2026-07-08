defmodule MaragaInfoWeb.Admin.SmsLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Campaigns
  alias MaragaInfo.Campaigns.SmsCampaign

  @poll_interval 2_000
  @default_attrs %{
    "title" => "Grassroots update",
    "sender_id" => System.get_env("SASASIGNAL_SENDER_ID") || "Maraga 27",
    "callback_url" => System.get_env("SASASIGNAL_CALLBACK_URL") || "",
    "message" =>
      "Hello {{first_name}}, thank you for standing with the movement. More updates shortly."
  }

  @impl true
  def mount(_params, _session, socket) do
    campaign = %SmsCampaign{}
    changeset = Campaigns.change_sms_campaign(campaign, @default_attrs)

    {:ok,
     socket
     |> assign(:page_title, "SMS campaigns")
     |> assign(
       :page_subtitle,
       "Queue, throttle, and track SMS blasts to volunteers with phone numbers."
     )
     |> assign(:campaign, campaign)
     |> assign(:campaigns, [])
     |> assign(:recipient_count, Campaigns.sms_recipient_count())
     |> assign(:test_phone, "")
     |> assign(:test_first_name, "")
     |> assign(:confirm_send, false)
     |> assign(:polling, false)
     |> assign(:draft_params, @default_attrs)
     |> assign_form(changeset)
     |> load_campaigns()}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> assign(:current_path, URI.parse(url).path)
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate", %{"sms_campaign" => params}, socket) do
    params = merge_system_attrs(params, socket.assigns.campaign)

    changeset =
      socket.assigns.campaign
      |> Campaigns.change_sms_campaign(params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:draft_params, params)
     |> assign_form(changeset)}
  end

  def handle_event("save_draft", %{"sms_campaign" => params}, socket) do
    params = merge_system_attrs(params, socket.assigns.campaign)

    case persist(socket.assigns.campaign, params) do
      {:ok, campaign} ->
        if socket.assigns.live_action == :new do
          {:noreply,
           socket
           |> put_flash(:info, "SMS draft saved.")
           |> push_navigate(to: ~p"/admin/sms/#{campaign.id}")}
        else
          {:noreply,
           socket
           |> put_flash(:info, "SMS draft saved.")
           |> load_into_composer(campaign)
           |> load_campaigns()}
        end

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("update_test_recipient", %{"field" => field, "value" => value}, socket)
      when field in ["phone", "first_name"] do
    key = if field == "phone", do: :test_phone, else: :test_first_name
    {:noreply, assign(socket, key, value)}
  end

  def handle_event("send_test", %{"test_recipient" => params}, socket) do
    phone = params |> Map.get("phone", "") |> String.trim()
    first_name = params |> Map.get("first_name", "") |> String.trim()

    if phone == "" do
      {:noreply, put_flash(socket, :error, "Enter a phone number to send a test SMS to.")}
    else
      changeset =
        Campaigns.change_sms_campaign(socket.assigns.campaign, socket.assigns.draft_params)

      campaign = Ecto.Changeset.apply_changes(changeset)

      case Campaigns.send_test_sms(campaign, phone, first_name) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(:test_phone, phone)
           |> assign(:test_first_name, first_name)
           |> put_flash(:info, "Test SMS sent to #{phone}.")}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Could not send test SMS: #{inspect(reason)}")}
      end
    end
  end

  def handle_event("request_send", _params, socket) do
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
    case Campaigns.send_sms_campaign(socket.assigns.campaign) do
      {:ok, _campaign} ->
        {:noreply,
         socket
         |> assign(:confirm_send, false)
         |> put_flash(:info, "SMS sending started — delivery is running in the background.")
         |> push_navigate(to: ~p"/admin/sms")}

      {:error, :no_recipients} ->
        {:noreply,
         socket
         |> assign(:confirm_send, false)
         |> put_flash(:error, "There are no volunteers with a phone number to send to.")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:confirm_send, false)
         |> put_flash(:error, "Could not start sending: #{inspect(reason)}")}
    end
  end

  def handle_event("new_campaign", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/admin/sms/new")}
  end

  def handle_event("edit_campaign", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/admin/sms/#{id}")}
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

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "SMS campaigns")
    |> assign(
      :page_subtitle,
      "Queue, throttle, and track SMS blasts to volunteers with phone numbers."
    )
    |> load_campaigns()
  end

  defp apply_action(socket, :new, _params) do
    campaign = %SmsCampaign{}
    changeset = Campaigns.change_sms_campaign(campaign, @default_attrs)

    socket
    |> assign(:page_title, "New SMS campaign")
    |> assign(:campaign, campaign)
    |> assign(:draft_params, @default_attrs)
    |> assign_form(changeset)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    campaign = Campaigns.get_sms_campaign!(id)
    params = sms_params(campaign)

    socket
    |> assign(:page_title, campaign.title)
    |> load_into_composer(campaign)
    |> assign(:draft_params, params)
    |> assign_form(Campaigns.change_sms_campaign(campaign, params))
  end

  defp persist(%SmsCampaign{id: nil}, params), do: Campaigns.create_sms_campaign(params)

  defp persist(%SmsCampaign{} = campaign, params),
    do: Campaigns.update_sms_campaign(campaign, params)

  defp load_campaigns(socket) do
    campaigns = Campaigns.list_sms_campaigns()

    socket
    |> assign(:campaigns, campaigns)
    |> maybe_start_polling(campaigns)
  end

  defp maybe_start_polling(socket, campaigns) do
    if Enum.any?(campaigns, &(&1.status == "sending")) and not socket.assigns.polling do
      schedule_tick()
      assign(socket, :polling, true)
    else
      socket
    end
  end

  defp schedule_tick, do: Process.send_after(self(), :tick, @poll_interval)

  defp load_into_composer(socket, campaign) do
    socket
    |> assign(:campaign, campaign)
    |> assign(:draft_params, sms_params(campaign))
  end

  defp sms_params(campaign) do
    %{
      "title" => campaign.title || "",
      "message" => campaign.message || ""
    }
  end

  defp merge_system_attrs(params, campaign) do
    params
    |> Map.new()
    |> Map.put("sender_id", configured_sender_id(campaign))
    |> Map.put("callback_url", configured_callback_url(campaign))
  end

  defp configured_sender_id(%SmsCampaign{sender_id: sender_id})
       when is_binary(sender_id) and sender_id != "" do
    sender_id
  end

  defp configured_sender_id(_campaign) do
    System.get_env("SASASIGNAL_SENDER_ID") || "Maraga 27"
  end

  defp configured_callback_url(%SmsCampaign{callback_url: callback_url})
       when is_binary(callback_url) and callback_url != "" do
    callback_url
  end

  defp configured_callback_url(_campaign) do
    System.get_env("SASASIGNAL_CALLBACK_URL") || ""
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp status_tone("draft"), do: "draft"
  defp status_tone("sending"), do: "neutral"
  defp status_tone("sent"), do: "published"
  defp status_tone(_status), do: "neutral"

  defp success_rate(%SmsCampaign{recipient_count: 0}), do: "0%"

  defp success_rate(%SmsCampaign{} = campaign) do
    "#{round(campaign.sent_count / campaign.recipient_count * 100)}%"
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
          type="button"
          phx-click="new_campaign"
          class="inline-flex items-center gap-2 rounded-lg bg-blueink px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blueink/90"
        >
          <.icon name="hero-plus-mini" class="h-4 w-4" /> New SMS campaign
        </button>
      </:actions>

      <div class="grid gap-6 xl:grid-cols-[minmax(0,1.15fr)_minmax(20rem,0.85fr)]">
        <div class="space-y-6">
          <.admin_panel
            title="Composer"
            subtitle="Draft your message, test it, then queue the campaign with Oban-managed backoff."
          >
            <div class="mb-5 grid gap-4 md:grid-cols-3">
              <.admin_stat
                title="Reachable phones"
                value={Integer.to_string(@recipient_count)}
                hint="Volunteers currently eligible for SMS campaigns"
              />
              <.admin_stat
                title="Queue"
                value="sms"
                hint="Dedicated low-concurrency Oban queue"
                tone="accent"
              />
              <.admin_stat
                title="Retries"
                value="5 attempts"
                hint="Exponential backoff protects the provider"
              />
            </div>

            <.form
              for={@form}
              id="sms-campaign-form"
              phx-change="validate"
              phx-submit="save_draft"
              class="space-y-4"
            >
              <.input
                field={@form[:title]}
                label="Campaign title"
                placeholder="County coordinators update"
              />
              <.input
                field={@form[:message]}
                type="textarea"
                label="SMS message"
                rows="6"
                placeholder="Hello {{first_name}}, ..."
              />
              <p class="text-xs text-zinc-500">
                Supports placeholders like <code>&lbrace;&lbrace;first_name&rbrace;&rbrace;</code>
                and <code>&lbrace;&lbrace;name&rbrace;&rbrace;</code>.
              </p>
              <div class="flex flex-wrap gap-3">
                <button
                  type="submit"
                  class="inline-flex items-center gap-2 rounded-lg bg-zinc-900 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-zinc-800"
                >
                  Save draft
                </button>
                <button
                  :if={@campaign.status == "draft"}
                  type="button"
                  phx-click="request_send"
                  class="inline-flex items-center gap-2 rounded-lg bg-green-700 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-green-600"
                >
                  Queue campaign
                </button>
                <.link
                  :if={@campaign.id && @campaign.status != "draft"}
                  navigate={~p"/admin/sms/#{@campaign.id}/analytics"}
                  class="inline-flex items-center gap-2 rounded-lg border border-zinc-300 bg-white px-4 py-2.5 text-sm font-semibold text-zinc-700 transition hover:bg-zinc-50"
                >
                  View analytics
                </.link>
              </div>
            </.form>
          </.admin_panel>

          <.admin_panel
            title="Test SMS"
            subtitle="Send the current draft to one phone number before you queue the full campaign."
          >
            <.form
              for={%{}}
              id="sms-test-form"
              phx-submit="send_test"
              class="grid gap-4 md:grid-cols-2"
            >
              <.input
                name="test_recipient[phone]"
                value={@test_phone}
                label="Phone number"
                placeholder="0700123456"
                phx-change="update_test_recipient"
                phx-value-field="phone"
              />
              <.input
                name="test_recipient[first_name]"
                value={@test_first_name}
                label="First name"
                placeholder="Michael"
                phx-change="update_test_recipient"
                phx-value-field="first_name"
              />
              <div class="md:col-span-2">
                <button
                  type="submit"
                  class="inline-flex items-center gap-2 rounded-lg border border-zinc-300 bg-white px-4 py-2.5 text-sm font-semibold text-zinc-700 transition hover:bg-zinc-50"
                >
                  Send test SMS
                </button>
              </div>
            </.form>
          </.admin_panel>
        </div>

        <.admin_panel
          title="Campaign history"
          subtitle="Monitor draft, sending, and sent SMS campaigns."
        >
          <div
            :if={@campaigns == []}
            class="rounded-xl border border-dashed border-zinc-300 px-6 py-10 text-center text-sm text-zinc-500"
          >
            No SMS campaigns yet.
          </div>

          <div :if={@campaigns != []} class="space-y-3">
            <button
              :for={campaign <- @campaigns}
              type="button"
              phx-click="edit_campaign"
              phx-value-id={campaign.id}
              class="w-full rounded-xl border border-zinc-200 bg-white p-4 text-left transition hover:border-zinc-300 hover:bg-zinc-50"
            >
              <div class="flex items-start justify-between gap-3">
                <div>
                  <p class="text-sm font-semibold text-zinc-900">{campaign.title}</p>
                  <p class="mt-1 text-sm text-zinc-500 line-clamp-2">{campaign.message}</p>
                </div>
                <.admin_badge tone={status_tone(campaign.status)} label={campaign.status} />
              </div>
              <div class="mt-3 flex flex-wrap gap-4 text-xs text-zinc-500">
                <span>{campaign.recipient_count} recipients</span>
                <span>{campaign.sent_count} sent</span>
                <span>{campaign.failed_count} failed</span>
                <span>Success {success_rate(campaign)}</span>
              </div>
            </button>
          </div>
        </.admin_panel>
      </div>

      <div
        :if={@confirm_send}
        class="fixed inset-0 z-50 flex items-center justify-center bg-zinc-950/50 px-4"
      >
        <div class="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl">
          <h2 class="text-lg font-semibold text-zinc-900">Queue this SMS campaign?</h2>
          <p class="mt-2 text-sm text-zinc-600">
            This will snapshot {@recipient_count} volunteer phone numbers and queue background jobs on the `sms` Oban queue.
          </p>
          <div class="mt-6 flex justify-end gap-3">
            <button
              type="button"
              phx-click="cancel_send"
              class="rounded-lg border border-zinc-300 bg-white px-4 py-2.5 text-sm font-semibold text-zinc-700 transition hover:bg-zinc-50"
            >
              Cancel
            </button>
            <button
              type="button"
              phx-click="confirm_send"
              class="rounded-lg bg-green-700 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-green-600"
            >
              Start sending
            </button>
          </div>
        </div>
      </div>
    </.admin_shell>
    """
  end
end
