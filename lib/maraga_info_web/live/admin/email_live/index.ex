defmodule MaragaInfoWeb.Admin.EmailLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Campaigns
  alias MaragaInfo.Campaigns.CampaignEmail
  alias MaragaInfo.Campaigns.EmailCampaign
  alias MaragaInfo.Campaigns.NewsletterBuilder
  alias MaragaInfo.Content
  alias MaragaInfoWeb.Uploads
  alias Phoenix.LiveView.JS

  @poll_interval 2_000

  @max_image_mb 8
  defp max_image_mb, do: @max_image_mb

  @default_sections [
    %{
      "type" => "greeting",
      "eyebrow" => "This week on the trail",
      "title" => "Building a Kenya Rooted in Integrity & Justice",
      "greeting" => "Hello {{first_name}},"
    },
    %{
      "type" => "text",
      "body" =>
        "Thank you for standing with the movement. Write your main message here. Use {{first_name}} anywhere to greet each volunteer personally."
    },
    %{
      "type" => "highlights",
      "label" => "Highlights this week",
      "items" => [
        "Add your first highlight here",
        "Add another highlight",
        "And one more"
      ]
    },
    %{
      "type" => "cta",
      "url" => "https://donations.davidmaraga.com/",
      "label" => "I Would Like to Donate",
      "subtext" => "Every contribution powers grassroots organizing across Kenya."
    },
    %{
      "type" => "signature",
      "salutation" => "With gratitude,",
      "name" => "The Maraga 2027 Team",
      "tagline" => "Integrity · Justice · Service"
    }
  ]

  @default_attrs %{
    "subject" => "Kenya Cannot Wait. Be at Ufungamano This Tuesday.",
    "preheader" => "Maraga's State of the Nation — Tuesday, June 16 at Ufungamano House.",
    "sender_name" => "David Maraga Campaign",
    "sender_title" => "Ukombozi 2027",
    "body" => "",
    "ab_test" => "false",
    "subject_b" => "It's Time. Stand With Maraga This Tuesday.",
    "sender_name_b" => "Team Maraga",
    "body_b" => "",
    "sections" => []
  }

  @section_types ~w(greeting text highlights cta image signature)
  @section_field_name_regex ~r/^section_(\d+)_(text_color|button_color|shape|align)$/
  @email_branding_fields [
    {"masthead_logo_url", "email.masthead.logo_url"},
    {"masthead_logo_alt", "email.masthead.logo_alt"},
    {"footer_social_heading", "email.footer.social_heading"},
    {"footer_contact_name", "email.footer.contact_name"},
    {"footer_contact_address", "email.footer.contact_address"},
    {"footer_phone", "email.footer.phone"},
    {"footer_website_url", "email.footer.website_url"},
    {"footer_website_label", "email.footer.website_label"},
    {"footer_legal_text", "email.footer.legal_text"},
    {"footer_unsubscribe_url", "email.footer.unsubscribe_url"},
    {"footer_unsubscribe_label", "email.footer.unsubscribe_label"},
    {"footer_preferences_url", "email.footer.preferences_url"},
    {"footer_preferences_label", "email.footer.preferences_label"},
    {"footer_browser_url", "email.footer.browser_url"},
    {"footer_browser_label", "email.footer.browser_label"},
    {"footer_social_x_url", "email.footer.social.x_url"},
    {"footer_social_instagram_url", "email.footer.social.instagram_url"},
    {"footer_social_youtube_url", "email.footer.social.youtube_url"},
    {"footer_social_facebook_url", "email.footer.social.facebook_url"},
    {"footer_social_tiktok_url", "email.footer.social.tiktok_url"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Email broadcasts")
     |> assign(
       :page_subtitle,
       "Build a newsletter with the section editor and send it to the whole volunteer database. The UKATIBA masthead and footer are always included."
     )
     |> assign(:recipient_count, Campaigns.recipient_count())
     |> assign(:test_email, "")
     |> assign(:test_first_name, "")
     |> assign(:preview_variant, "A")
     |> assign(:confirm_send, false)
     |> assign(:polling, false)
     |> assign(:section_types, @section_types)
     |> assign(:target_section, nil)
     |> assign_email_branding_form()
     |> allow_upload(:masthead_logo,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: @max_image_mb * 1_000_000,
       auto_upload: true,
       progress: &handle_progress/3
     )
     |> allow_upload(:section_image,
       accept: ~w(.jpg .jpeg .png .webp .gif),
       max_entries: 1,
       max_file_size: @max_image_mb * 1_000_000,
       auto_upload: true,
       progress: &handle_progress/3
     )
     |> reset_composer()
     |> load_campaigns()}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> assign(:current_path, URI.parse(url).path)
     |> apply_action(socket.assigns.live_action, params)}
  end

  ## Events — metadata form

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
     |> refresh_preview()}
  end

  def handle_event("update_test_recipient", %{"field" => field, "value" => value}, socket)
      when field in ["email", "first_name"] do
    key =
      case field do
        "email" -> :test_email
        "first_name" -> :test_first_name
      end

    {:noreply, assign(socket, key, value)}
  end

  def handle_event("update_test_recipient", %{"test_recipient" => params}, socket) do
    {:noreply,
     socket
     |> assign(:test_email, Map.get(params, "email", ""))
     |> assign(:test_first_name, Map.get(params, "first_name", ""))}
  end

  def handle_event("save_email_branding", %{"email_branding" => params}, socket) do
    Content.upsert_settings(email_branding_params_to_settings(params))

    {:noreply,
     socket
     |> assign_email_branding_form()
     |> refresh_preview()
     |> put_flash(:info, "Email masthead and footer saved.")}
  end

  def handle_event("preview_variant", %{"variant" => variant}, socket)
      when variant in ~w(A B) do
    changeset = Campaigns.change_campaign(socket.assigns.campaign, socket.assigns.draft_params)

    {:noreply,
     socket
     |> assign(:preview_variant, variant)
     |> refresh_preview(Ecto.Changeset.apply_changes(changeset))}
  end

  def handle_event("save_draft", %{"email_campaign" => params}, socket) do
    case persist(socket.assigns.campaign, params_for_persist(socket, params)) do
      {:ok, campaign} ->
        if socket.assigns.live_action == :new do
          {:noreply,
           socket
           |> put_flash(:info, "Draft saved.")
           |> push_navigate(to: ~p"/admin/emails/#{campaign.id}")}
        else
          {:noreply,
           socket
           |> put_flash(:info, "Draft saved.")
           |> load_into_composer(campaign)
           |> load_campaigns()}
        end

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("send_test", %{"test_recipient" => params}, socket) do
    campaign_params = socket.assigns.draft_params
    email = params |> Map.get("email", "") |> String.trim()
    first_name = params |> Map.get("first_name", "") |> String.trim()
    variant = socket.assigns.preview_variant

    if email == "" do
      {:noreply, put_flash(socket, :error, "Enter an email address to send a test to.")}
    else
      sections = socket.assigns.sections
      changeset = Campaigns.change_campaign(socket.assigns.campaign, campaign_params)
      campaign = Ecto.Changeset.apply_changes(changeset) |> Map.put(:sections, sections)

      case IO.inspect(Campaigns.send_test_email(campaign, email, variant, first_name)) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(:test_email, email)
           |> assign(:test_first_name, first_name)
           |> put_flash(:info, "Test of variant #{variant} sent to #{email}.")}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Could not send test: #{inspect(reason)}")}
      end
    end
  end

  def handle_event("send_test", _params, socket) do
    email = String.trim(socket.assigns.test_email)
    first_name = String.trim(socket.assigns.test_first_name)
    variant = socket.assigns.preview_variant

    if email == "" do
      {:noreply, put_flash(socket, :error, "Enter an email address to send a test to.")}
    else
      sections = socket.assigns.sections
      changeset = Campaigns.change_campaign(socket.assigns.campaign, socket.assigns.draft_params)
      campaign = Ecto.Changeset.apply_changes(changeset) |> Map.put(:sections, sections)

      case Campaigns.send_test_email(campaign, email, variant, first_name) do
        {:ok, _} ->
          {:noreply, put_flash(socket, :info, "Test of variant #{variant} sent to #{email}.")}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Could not send test: #{inspect(reason)}")}
      end
    end
  end

  def handle_event("request_send", _payload, socket) do
    case persist(socket.assigns.campaign, params_for_persist(socket, socket.assigns.draft_params)) do
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
         |> push_navigate(to: ~p"/admin/emails")}

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
    {:noreply, push_navigate(socket, to: ~p"/admin/emails/new")}
  end

  def handle_event("edit_campaign", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/admin/emails/#{id}")}
  end

  ## Events — section builder

  def handle_event("add_section", params, socket) do
    type = params["section_type"] || params["type"] || params["value"]

    if type in @section_types do
      sections = socket.assigns.sections ++ [default_section(type)]
      {:noreply, socket |> assign(:sections, sections) |> refresh_preview()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_section", %{"index" => index}, socket) do
    idx = String.to_integer(index)
    sections = List.delete_at(socket.assigns.sections, idx)
    {:noreply, socket |> assign(:sections, sections) |> refresh_preview()}
  end

  def handle_event("move_section", %{"index" => index, "direction" => direction}, socket) do
    idx = String.to_integer(index)
    sections = socket.assigns.sections
    len = length(sections)

    new_sections =
      case direction do
        "up" when idx > 0 -> swap_at(sections, idx, idx - 1)
        "down" when idx < len - 1 -> swap_at(sections, idx, idx + 1)
        _ -> sections
      end

    {:noreply, socket |> assign(:sections, new_sections) |> refresh_preview()}
  end

  def handle_event(
        "update_section_field",
        %{"index" => index, "field" => field, "value" => value},
        socket
      ) do
    idx = String.to_integer(index)
    sections = List.update_at(socket.assigns.sections, idx, &Map.put(&1, field, value))
    {:noreply, socket |> assign(:sections, sections) |> refresh_preview()}
  end

  def handle_event("update_section_field", params, socket) do
    case named_section_field_change(params) do
      {:ok, index, field, value} ->
        sections = List.update_at(socket.assigns.sections, index, &Map.put(&1, field, value))
        {:noreply, socket |> assign(:sections, sections) |> refresh_preview()}

      :error ->
        {:noreply, socket}
    end
  end

  def handle_event("target_section", %{"index" => index}, socket) do
    {:noreply, assign(socket, :target_section, String.to_integer(index))}
  end

  def handle_event("cancel_upload", %{"upload" => name, "ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, String.to_existing_atom(name), ref)}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :section_image, ref)}
  end

  def handle_event("add_highlight_item", %{"index" => index}, socket) do
    idx = String.to_integer(index)

    sections =
      List.update_at(socket.assigns.sections, idx, fn s ->
        Map.update(s, "items", [""], &(&1 ++ [""]))
      end)

    {:noreply, socket |> assign(:sections, sections) |> refresh_preview()}
  end

  def handle_event(
        "remove_highlight_item",
        %{"section_index" => si, "item_index" => ii},
        socket
      ) do
    sidx = String.to_integer(si)
    iidx = String.to_integer(ii)

    sections =
      List.update_at(socket.assigns.sections, sidx, fn s ->
        items = Map.get(s, "items", [])
        Map.put(s, "items", List.delete_at(items, iidx))
      end)

    {:noreply, socket |> assign(:sections, sections) |> refresh_preview()}
  end

  def handle_event(
        "update_highlight_item",
        %{"section_index" => si, "item_index" => ii, "value" => value},
        socket
      ) do
    sidx = String.to_integer(si)
    iidx = String.to_integer(ii)

    sections =
      List.update_at(socket.assigns.sections, sidx, fn s ->
        items = Map.get(s, "items", [])
        Map.put(s, "items", List.replace_at(items, iidx, value))
      end)

    {:noreply, socket |> assign(:sections, sections) |> refresh_preview()}
  end

  def handle_event("switch_builder_mode", %{"mode" => mode}, socket) do
    {sections, body_note} =
      case mode do
        "sections" -> {@default_sections, nil}
        _ -> {[], nil}
      end

    socket =
      socket
      |> assign(:builder_mode, mode)
      |> assign(:sections, sections)
      |> refresh_preview()

    socket =
      if body_note, do: put_flash(socket, :info, body_note), else: socket

    {:noreply, socket}
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

  ## Uploads

  defp handle_progress(:masthead_logo, entry, socket) do
    if entry.done? do
      url = consume_uploaded_entry(socket, entry, fn meta -> Uploads.store_entry(meta, entry) end)

      Content.upsert_settings(%{"email.masthead.logo_url" => url})

      {:noreply,
       socket
       |> assign_email_branding_form()
       |> refresh_preview()}
    else
      {:noreply, socket}
    end
  end

  defp handle_progress(:section_image, entry, socket) do
    if entry.done? and not is_nil(socket.assigns.target_section) do
      url = consume_uploaded_entry(socket, entry, fn meta -> Uploads.store_entry(meta, entry) end)

      sections =
        List.update_at(socket.assigns.sections, socket.assigns.target_section, fn section ->
          Map.put(section, "url", absolute_url(url))
        end)

      {:noreply, socket |> assign(:sections, sections) |> refresh_preview()}
    else
      {:noreply, socket}
    end
  end

  # Uploaded files are served from `/uploads/...`; email clients need an absolute
  # URL. We always anchor to the production domain (not `Endpoint.url()`) so
  # images sent from a local/dev server still resolve for recipients.
  defp absolute_url(url), do: MaragaInfoWeb.Seo.absolute_url(url)

  defp preview_image_url("https://davidmaraga.info/uploads/" <> path), do: "/uploads/" <> path
  defp preview_image_url(url), do: url

  defp preview_sections(sections) do
    Enum.map(sections, fn
      %{"type" => "image", "url" => url} = section ->
        Map.put(section, "url", preview_image_url(url))

      section ->
        section
    end)
  end

  ## Helpers

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Email broadcasts")
    |> assign(
      :page_subtitle,
      "Build a newsletter with the section editor and send it to the whole volunteer database."
    )
    |> load_campaigns()
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New email")
    |> assign(
      :page_subtitle,
      "Build sections below. The UKATIBA masthead and footer are always included."
    )
    |> reset_composer()
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    campaign = Campaigns.get_campaign!(id)

    socket
    |> assign(:page_title, campaign.subject)
    |> assign(
      :page_subtitle,
      "#{String.capitalize(campaign.status)} · updated #{format_datetime(campaign.updated_at)}"
    )
    |> load_into_composer(campaign)
  end

  defp persist(%EmailCampaign{id: nil}, params), do: Campaigns.create_campaign(params)

  defp persist(%EmailCampaign{} = campaign, params),
    do: Campaigns.update_campaign(campaign, params)

  defp params_for_persist(%{assigns: %{builder_mode: "sections", sections: sections}}, params)
       when is_list(sections) and sections != [] do
    preheader = Map.get(params, "preheader", "")
    body = NewsletterBuilder.build_html(sections, preheader: preheader)

    params
    |> Map.put("sections", sections)
    |> Map.put("body", body)
    |> Map.put("body_b", body)
  end

  defp params_for_persist(socket, params) do
    Map.put(params, "sections", socket.assigns.sections)
  end

  defp reset_composer(socket) do
    campaign = %EmailCampaign{}
    changeset = Campaigns.change_campaign(campaign, @default_attrs)

    socket
    |> assign(:campaign, campaign)
    |> assign(:sections, @default_sections)
    |> assign(:builder_mode, "sections")
    |> assign(:draft_params, @default_attrs)
    |> assign(:preview_variant, "A")
    |> assign_form(changeset)
    |> refresh_preview()
  end

  defp load_into_composer(socket, %EmailCampaign{} = campaign) do
    sections = campaign.sections || []
    builder_mode = if sections != [], do: "sections", else: "html"
    changeset = Campaigns.change_campaign(campaign)

    socket
    |> assign(:campaign, campaign)
    |> assign(:sections, sections)
    |> assign(:builder_mode, builder_mode)
    |> assign(:draft_params, campaign_to_params(campaign))
    |> assign_form(changeset)
    |> refresh_preview()
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

  defp refresh_preview(socket) do
    changeset = Campaigns.change_campaign(socket.assigns.campaign, socket.assigns.draft_params)
    campaign = Ecto.Changeset.apply_changes(changeset)
    refresh_preview(socket, campaign)
  end

  defp refresh_preview(socket, %EmailCampaign{} = campaign) do
    sections = socket.assigns.sections
    variant = effective_preview_variant(socket, campaign)
    preheader = campaign.preheader || ""

    html =
      if socket.assigns.builder_mode == "sections" and sections != [] do
        NewsletterBuilder.build_html(preview_sections(sections), preheader: preheader)
        |> CampaignEmail.personalize(%{name: "Jane Mwangi"})
      else
        content = CampaignEmail.variant_content(campaign, variant)
        CampaignEmail.render_html(content, %{name: "Jane Mwangi"})
      end

    socket
    |> assign(:preview_variant, variant)
    |> assign(:preview_html, html)
  end

  defp effective_preview_variant(socket, %EmailCampaign{ab_test: true}),
    do: socket.assigns.preview_variant

  defp effective_preview_variant(_socket, _campaign), do: "A"

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

  defp swap_at(list, i, j) do
    a = Enum.at(list, i)
    b = Enum.at(list, j)
    list |> List.replace_at(i, b) |> List.replace_at(j, a)
  end

  defp named_section_field_change(params) do
    Enum.find_value(params, :error, fn
      {name, value} when is_binary(value) ->
        case Regex.run(@section_field_name_regex, name) do
          [_, index, field] -> {:ok, String.to_integer(index), field, value}
          _ -> nil
        end

      _ ->
        nil
    end)
  end

  defp entries_for(upload, target_section, index) when target_section == index,
    do: upload.entries

  defp entries_for(_upload, _target, _index), do: []

  defp image_errors(upload) do
    Enum.flat_map(upload.entries, &upload_errors(upload, &1)) ++ upload_errors(upload)
  end

  defp upload_error_to_string(:too_large), do: "File is too large (max #{@max_image_mb}MB)"
  defp upload_error_to_string(:too_many_files), do: "Too many files"
  defp upload_error_to_string(:not_accepted), do: "Unsupported file type"
  defp upload_error_to_string(_), do: "Invalid file"

  defp default_section("greeting") do
    %{
      "type" => "greeting",
      "eyebrow" => "This week on the trail",
      "title" => "Enter your headline here",
      "greeting" => "Hello {{first_name}},"
    }
  end

  defp default_section("text"), do: %{"type" => "text", "body" => "Write your message here."}

  defp default_section("highlights") do
    %{"type" => "highlights", "label" => "Highlights this week", "items" => ["", ""]}
  end

  defp default_section("cta") do
    %{
      "type" => "cta",
      "url" => "https://donations.davidmaraga.com/",
      "label" => "I Would Like to Donate",
      "subtext" => "Every contribution powers grassroots organizing across Kenya.",
      "text_color" => "#026631",
      "button_color" => "#ceb04e",
      "shape" => "pill",
      "align" => "center"
    }
  end

  defp default_section("image"),
    do: %{"type" => "image", "url" => "", "alt" => "", "link_url" => ""}

  defp default_section("signature") do
    %{
      "type" => "signature",
      "salutation" => "With gratitude,",
      "name" => "The Maraga 2027 Team",
      "tagline" => "Integrity · Justice · Service"
    }
  end

  defp default_section(_), do: %{"type" => "text", "body" => ""}

  defp section_type_label("greeting"), do: "Greeting / Title"
  defp section_type_label("text"), do: "Body Text"
  defp section_type_label("highlights"), do: "Highlights Box"
  defp section_type_label("cta"), do: "Call-to-Action Button"
  defp section_type_label("image"), do: "Image"
  defp section_type_label("signature"), do: "Signature"
  defp section_type_label(t), do: t

  defp section_type_color("greeting"), do: "bg-green-50 text-green-700 ring-green-600/20"
  defp section_type_color("text"), do: "bg-blue-50 text-blue-700 ring-blue-600/20"
  defp section_type_color("highlights"), do: "bg-amber-50 text-amber-700 ring-amber-600/20"
  defp section_type_color("cta"), do: "bg-yellow-50 text-yellow-700 ring-yellow-600/20"
  defp section_type_color("image"), do: "bg-purple-50 text-purple-700 ring-purple-600/20"
  defp section_type_color("signature"), do: "bg-zinc-100 text-zinc-700 ring-zinc-400/20"
  defp section_type_color(_), do: "bg-zinc-100 text-zinc-700 ring-zinc-400/20"

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
        <.link
          :if={@live_action in [:new, :show]}
          navigate={~p"/admin/emails"}
          class="inline-flex items-center gap-2 rounded-lg border border-zinc-200 bg-white px-4 py-2.5 text-sm font-semibold text-zinc-700 transition hover:bg-zinc-50"
        >
          <.icon name="hero-arrow-left-mini" class="h-4 w-4" /> All broadcasts
        </.link>
        <.link
          :if={@live_action == :index}
          navigate={~p"/admin/emails/new"}
          class="inline-flex items-center gap-2 rounded-lg border border-zinc-200 bg-white px-4 py-2.5 text-sm font-semibold text-zinc-700 transition hover:bg-zinc-50"
        >
          <.icon name="hero-document-plus-mini" class="h-4 w-4" /> New email
        </.link>
      </:actions>

      <div class="space-y-6">
        <div
          :if={@live_action in [:new, :show]}
          class="grid gap-6 xl:grid-cols-[minmax(0,38rem)_minmax(0,1fr)] xl:items-start"
        >
          <div class="xl:sticky xl:top-6 xl:h-[calc(100vh-8.5rem)] xl:overflow-y-auto xl:pr-2">
            <div class="space-y-6">
              <.form
                for={@form}
                id="email-composer"
                phx-change="validate"
                phx-submit="save_draft"
                class="space-y-6"
              >
                <.admin_panel
                  title="Header"
                  subtitle="Campaign metadata, sender details, and send controls."
                >
                  <div class="space-y-4">
                    <.input field={@form[:subject]} type="text" label="Subject line" required />
                    <.input
                      field={@form[:preheader]}
                      type="text"
                      label="Preview text"
                      placeholder="Short summary shown in the inbox preview"
                    />
                    <.input
                      field={@form[:sender_name]}
                      type="text"
                      label="Sender name (From)"
                      required
                    />

                    <div class="rounded-xl border border-zinc-200 bg-zinc-50 p-4">
                      <.input
                        field={@form[:ab_test]}
                        type="checkbox"
                        label="Run an A/B test (split the list evenly between two versions)"
                      />

                      <div
                        :if={@form[:ab_test].value in [true, "true"]}
                        class="mt-4 space-y-4 border-t border-zinc-200 pt-4"
                      >
                        <p class="text-xs text-zinc-500">
                          A/B testing varies the subject line and sender name. Both variants share the same content sections.
                        </p>
                        <.input
                          field={@form[:subject_b]}
                          type="text"
                          label="Variant B — subject line"
                        />
                        <.input
                          field={@form[:sender_name_b]}
                          type="text"
                          label="Variant B — sender name"
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
                          value={@test_email}
                          phx-blur="update_test_recipient"
                          phx-value-field="email"
                          placeholder="you@example.com"
                          class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                        />
                        <input
                          type="text"
                          value={@test_first_name}
                          phx-blur="update_test_recipient"
                          phx-value-field="first_name"
                          placeholder="First name (optional)"
                          class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20 sm:max-w-[14rem]"
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

                <.admin_panel
                  title="Body"
                  subtitle="Build the body content while the masthead and footer stay shared."
                >
                  <div class="space-y-4">
                    <%!-- Section builder / raw HTML toggle --%>
                    <div class="flex items-center justify-between border-b border-zinc-100 pb-2">
                      <p class="text-sm font-semibold text-zinc-900">Email content</p>
                      <div class="flex rounded-lg border border-zinc-200 bg-zinc-100 p-0.5 text-xs">
                        <button
                          type="button"
                          phx-click="switch_builder_mode"
                          phx-value-mode="sections"
                          class={[
                            "rounded-md px-3 py-1 font-medium transition",
                            @builder_mode == "sections" && "bg-white text-zinc-900 shadow-sm",
                            @builder_mode != "sections" && "text-zinc-500 hover:text-zinc-700"
                          ]}
                        >
                          Section builder
                        </button>
                        <button
                          type="button"
                          phx-click="switch_builder_mode"
                          phx-value-mode="html"
                          class={[
                            "rounded-md px-3 py-1 font-medium transition",
                            @builder_mode == "html" && "bg-white text-zinc-900 shadow-sm",
                            @builder_mode != "html" && "text-zinc-500 hover:text-zinc-700"
                          ]}
                        >
                          Raw HTML
                        </button>
                      </div>
                    </div>

                    <%!-- Section builder --%>
                    <div :if={@builder_mode == "sections"} class="space-y-3">
                      <%!-- Static masthead notice --%>
                      <div class="flex items-center gap-2 rounded-lg border border-zinc-100 bg-zinc-50 px-3 py-2">
                        <.icon
                          name="hero-lock-closed-mini"
                          class="h-3.5 w-3.5 shrink-0 text-zinc-400"
                        />
                        <p class="text-xs text-zinc-500">
                          UKATIBA masthead, social icons and footer are always included.
                        </p>
                      </div>

                      <%!-- Section cards --%>
                      <div
                        :for={{section, idx} <- Enum.with_index(@sections)}
                        class="rounded-xl border border-zinc-200 bg-white"
                      >
                        <%!-- Card header --%>
                        <div class="flex items-center justify-between border-b border-zinc-100 px-4 py-2.5">
                          <span class={[
                            "inline-flex items-center rounded-md px-2 py-0.5 text-xs font-medium ring-1 ring-inset",
                            section_type_color(section["type"])
                          ]}>
                            {section_type_label(section["type"])}
                          </span>
                          <div class="flex items-center gap-0.5">
                            <button
                              type="button"
                              phx-click="move_section"
                              phx-value-index={idx}
                              phx-value-direction="up"
                              disabled={idx == 0}
                              class="rounded p-1 text-zinc-400 transition hover:text-zinc-700 disabled:cursor-not-allowed disabled:opacity-30"
                              title="Move up"
                            >
                              <.icon name="hero-chevron-up-mini" class="h-4 w-4" />
                            </button>
                            <button
                              type="button"
                              phx-click="move_section"
                              phx-value-index={idx}
                              phx-value-direction="down"
                              disabled={idx == length(@sections) - 1}
                              class="rounded p-1 text-zinc-400 transition hover:text-zinc-700 disabled:cursor-not-allowed disabled:opacity-30"
                              title="Move down"
                            >
                              <.icon name="hero-chevron-down-mini" class="h-4 w-4" />
                            </button>
                            <button
                              type="button"
                              phx-click="remove_section"
                              phx-value-index={idx}
                              class="rounded p-1 text-red-400 transition hover:text-red-600"
                              title="Remove section"
                            >
                              <.icon name="hero-trash-mini" class="h-4 w-4" />
                            </button>
                          </div>
                        </div>

                        <%!-- Type-specific fields --%>
                        <div class="space-y-3 p-4">
                          <%!-- GREETING --%>
                          <div :if={section["type"] == "greeting"} class="space-y-3">
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-1">
                                Eyebrow text
                                <span class="font-normal text-zinc-400">(italic, optional)</span>
                              </label>
                              <input
                                type="text"
                                value={Map.get(section, "eyebrow", "")}
                                phx-blur="update_section_field"
                                phx-value-index={idx}
                                phx-value-field="eyebrow"
                                placeholder="e.g. This week on the trail"
                                class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                              />
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-1">
                                Headline
                              </label>
                              <input
                                type="text"
                                value={Map.get(section, "title", "")}
                                phx-blur="update_section_field"
                                phx-value-index={idx}
                                phx-value-field="title"
                                placeholder="Your big headline (shown in uppercase)"
                                class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                              />
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-1">
                                Greeting line
                              </label>
                              <input
                                type="text"
                                value={Map.get(section, "greeting", "Hello {{first_name}},")}
                                phx-blur="update_section_field"
                                phx-value-index={idx}
                                phx-value-field="greeting"
                                placeholder="Hello {{first_name}},"
                                class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                              />
                            </div>
                          </div>

                          <%!-- TEXT --%>
                          <div :if={section["type"] == "text"}>
                            <label class="block text-xs font-medium text-zinc-700 mb-1">
                              Body text
                              <span class="font-normal text-zinc-400">
                                (use {"{{first_name}}"} to personalise)
                              </span>
                            </label>
                            <.section_rich_text
                              id={"rt-section-#{idx}"}
                              index={idx}
                              value={Map.get(section, "body", "")}
                            />
                          </div>

                          <%!-- HIGHLIGHTS --%>
                          <div :if={section["type"] == "highlights"} class="space-y-3">
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-1">
                                Box label
                              </label>
                              <input
                                type="text"
                                value={Map.get(section, "label", "")}
                                phx-blur="update_section_field"
                                phx-value-index={idx}
                                phx-value-field="label"
                                placeholder="Highlights this week"
                                class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                              />
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-2">
                                Bullet items
                              </label>
                              <div class="space-y-2">
                                <div
                                  :for={
                                    {item, iidx} <- Enum.with_index(Map.get(section, "items", []))
                                  }
                                  class="flex items-center gap-2"
                                >
                                  <span class="text-sm text-red-500 font-bold shrink-0">✓</span>
                                  <input
                                    type="text"
                                    value={item}
                                    phx-blur="update_highlight_item"
                                    phx-value-section_index={idx}
                                    phx-value-item_index={iidx}
                                    placeholder="Bullet item"
                                    class="flex-1 rounded-lg border border-zinc-300 px-3 py-1.5 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                                  />
                                  <button
                                    type="button"
                                    phx-click="remove_highlight_item"
                                    phx-value-section_index={idx}
                                    phx-value-item_index={iidx}
                                    class="shrink-0 rounded p-1 text-zinc-400 hover:text-red-500"
                                  >
                                    <.icon name="hero-x-mark-mini" class="h-4 w-4" />
                                  </button>
                                </div>
                                <button
                                  type="button"
                                  phx-click="add_highlight_item"
                                  phx-value-index={idx}
                                  class="text-xs font-medium text-green-700 hover:text-green-800"
                                >
                                  + Add item
                                </button>
                              </div>
                            </div>
                          </div>

                          <%!-- CTA --%>
                          <div :if={section["type"] == "cta"} class="space-y-3">
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-1">
                                Button label
                              </label>
                              <input
                                type="text"
                                value={Map.get(section, "label", "")}
                                phx-blur="update_section_field"
                                phx-value-index={idx}
                                phx-value-field="label"
                                placeholder="I Would Like to Donate"
                                class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                              />
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-1">
                                Button URL
                              </label>
                              <input
                                type="url"
                                value={Map.get(section, "url", "")}
                                phx-blur="update_section_field"
                                phx-value-index={idx}
                                phx-value-field="url"
                                placeholder="https://donations.davidmaraga.com/"
                                class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                              />
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-1">
                                Subtext <span class="font-normal text-zinc-400">(optional)</span>
                              </label>
                              <input
                                type="text"
                                value={Map.get(section, "subtext", "")}
                                phx-blur="update_section_field"
                                phx-value-index={idx}
                                phx-value-field="subtext"
                                placeholder="Every contribution powers grassroots organizing…"
                                class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                              />
                            </div>
                            <div class="grid grid-cols-2 gap-3">
                              <div>
                                <label class="block text-xs font-medium text-zinc-700 mb-1">
                                  Text color
                                </label>
                                <div class="flex items-center gap-2">
                                  <input
                                    type="color"
                                    name={"section_#{idx}_text_color"}
                                    value={Map.get(section, "text_color", "#026631")}
                                    phx-change="update_section_field"
                                    phx-value-index={idx}
                                    phx-value-field="text_color"
                                    class="h-9 w-10 shrink-0 cursor-pointer rounded-lg border border-zinc-300 p-1"
                                  />
                                  <input
                                    type="text"
                                    value={Map.get(section, "text_color", "#026631")}
                                    phx-blur="update_section_field"
                                    phx-value-index={idx}
                                    phx-value-field="text_color"
                                    placeholder="#026631"
                                    class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                                  />
                                </div>
                              </div>
                              <div>
                                <label class="block text-xs font-medium text-zinc-700 mb-1">
                                  Button color
                                </label>
                                <div class="flex items-center gap-2">
                                  <input
                                    type="color"
                                    name={"section_#{idx}_button_color"}
                                    value={Map.get(section, "button_color", "#ceb04e")}
                                    phx-change="update_section_field"
                                    phx-value-index={idx}
                                    phx-value-field="button_color"
                                    class="h-9 w-10 shrink-0 cursor-pointer rounded-lg border border-zinc-300 p-1"
                                  />
                                  <input
                                    type="text"
                                    value={Map.get(section, "button_color", "#ceb04e")}
                                    phx-blur="update_section_field"
                                    phx-value-index={idx}
                                    phx-value-field="button_color"
                                    placeholder="#ceb04e"
                                    class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                                  />
                                </div>
                              </div>
                            </div>
                            <div class="grid grid-cols-2 gap-3">
                              <div>
                                <label class="block text-xs font-medium text-zinc-700 mb-1">
                                  Button shape
                                </label>
                                <select
                                  phx-change="update_section_field"
                                  phx-value-index={idx}
                                  phx-value-field="shape"
                                  name={"section_#{idx}_shape"}
                                  class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                                >
                                  <option
                                    value="pill"
                                    selected={Map.get(section, "shape", "pill") == "pill"}
                                  >
                                    Pill
                                  </option>
                                  <option
                                    value="rounded"
                                    selected={Map.get(section, "shape", "pill") == "rounded"}
                                  >
                                    Rounded
                                  </option>
                                  <option
                                    value="square"
                                    selected={Map.get(section, "shape", "pill") == "square"}
                                  >
                                    Square
                                  </option>
                                </select>
                              </div>
                              <div>
                                <label class="block text-xs font-medium text-zinc-700 mb-1">
                                  Position
                                </label>
                                <select
                                  phx-change="update_section_field"
                                  phx-value-index={idx}
                                  phx-value-field="align"
                                  name={"section_#{idx}_align"}
                                  class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                                >
                                  <option
                                    value="left"
                                    selected={Map.get(section, "align", "center") == "left"}
                                  >
                                    Left
                                  </option>
                                  <option
                                    value="center"
                                    selected={Map.get(section, "align", "center") == "center"}
                                  >
                                    Center
                                  </option>
                                  <option
                                    value="right"
                                    selected={Map.get(section, "align", "center") == "right"}
                                  >
                                    Right
                                  </option>
                                </select>
                              </div>
                            </div>
                          </div>

                          <%!-- IMAGE --%>
                          <div :if={section["type"] == "image"} class="space-y-3">
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-1">
                                Image
                              </label>

                              <div
                                :if={Map.get(section, "url", "") != ""}
                                class="relative mb-2 overflow-hidden rounded-lg border border-zinc-200"
                              >
                                <img
                                  src={section |> Map.get("url") |> preview_image_url()}
                                  class="mx-auto max-h-48 w-full object-contain"
                                />
                                <button
                                  type="button"
                                  phx-click="update_section_field"
                                  phx-value-index={idx}
                                  phx-value-field="url"
                                  phx-value-value=""
                                  class="absolute right-2 top-2 rounded-md bg-white/90 p-1 text-zinc-700 shadow-sm transition hover:text-red-600"
                                  aria-label="Remove image"
                                >
                                  <.icon name="hero-x-mark-mini" class="h-4 w-4" />
                                </button>
                              </div>

                              <label
                                phx-click="target_section"
                                phx-value-index={idx}
                                class="flex cursor-pointer flex-col items-center justify-center gap-1 rounded-lg border border-dashed border-zinc-300 px-4 py-5 text-center text-sm text-zinc-600 transition hover:border-blueink hover:text-blueink"
                              >
                                <.icon name="hero-arrow-up-tray" class="h-5 w-5" />
                                <span class="font-medium">
                                  {if Map.get(section, "url", "") != "",
                                    do: "Replace image",
                                    else: "Upload image"}
                                </span>
                                <span class="text-xs text-zinc-400">
                                  JPG, PNG, GIF or WEBP up to {max_image_mb()}MB
                                </span>
                                <.live_file_input upload={@uploads.section_image} class="sr-only" />
                              </label>

                              <p
                                :for={
                                  entry <- entries_for(@uploads.section_image, @target_section, idx)
                                }
                                class="mt-2 text-xs text-zinc-500"
                              >
                                Uploading {entry.client_name} — {entry.progress}%
                              </p>

                              <p
                                :for={err <- image_errors(@uploads.section_image)}
                                :if={@target_section == idx}
                                class="mt-1 text-xs text-red-600"
                              >
                                {upload_error_to_string(err)}
                              </p>
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-1">
                                Image URL
                                <span class="font-normal text-zinc-400">
                                  (or paste an external link)
                                </span>
                              </label>
                              <input
                                type="url"
                                value={Map.get(section, "url", "")}
                                phx-blur="update_section_field"
                                phx-value-index={idx}
                                phx-value-field="url"
                                placeholder="https://davidmaraga.info/images/…"
                                class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                              />
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-1">
                                Alt text
                              </label>
                              <input
                                type="text"
                                value={Map.get(section, "alt", "")}
                                phx-blur="update_section_field"
                                phx-value-index={idx}
                                phx-value-field="alt"
                                placeholder="Describe the image for screen readers"
                                class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                              />
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-1">
                                Link URL <span class="font-normal text-zinc-400">(optional)</span>
                              </label>
                              <input
                                type="url"
                                value={Map.get(section, "link_url", "")}
                                phx-blur="update_section_field"
                                phx-value-index={idx}
                                phx-value-field="link_url"
                                placeholder="https://davidmaraga.info/"
                                class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                              />
                            </div>
                          </div>

                          <%!-- SIGNATURE --%>
                          <div :if={section["type"] == "signature"} class="space-y-3">
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-1">
                                Salutation
                              </label>
                              <input
                                type="text"
                                value={Map.get(section, "salutation", "")}
                                phx-blur="update_section_field"
                                phx-value-index={idx}
                                phx-value-field="salutation"
                                placeholder="With gratitude,"
                                class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                              />
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-1">
                                Name / Team
                              </label>
                              <input
                                type="text"
                                value={Map.get(section, "name", "")}
                                phx-blur="update_section_field"
                                phx-value-index={idx}
                                phx-value-field="name"
                                placeholder="The Maraga 2027 Team"
                                class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                              />
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-zinc-700 mb-1">
                                Tagline
                              </label>
                              <input
                                type="text"
                                value={Map.get(section, "tagline", "")}
                                phx-blur="update_section_field"
                                phx-value-index={idx}
                                phx-value-field="tagline"
                                placeholder="Integrity · Justice · Service"
                                class="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm text-zinc-900 placeholder:text-zinc-400 focus:border-blueink focus:outline-none focus:ring-2 focus:ring-blueink/20"
                              />
                            </div>
                          </div>
                        </div>
                      </div>

                      <%!-- Add section --%>
                      <div class="rounded-xl border border-dashed border-zinc-200 bg-zinc-50/50 p-4">
                        <p class="mb-2.5 text-xs font-semibold uppercase tracking-wide text-zinc-400">
                          Add a section
                        </p>
                        <div class="flex flex-wrap gap-2">
                          <button
                            :for={type <- @section_types}
                            type="button"
                            phx-click="add_section"
                            phx-value-section_type={type}
                            class="inline-flex items-center gap-1 rounded-lg border border-zinc-200 bg-white px-3 py-1.5 text-xs font-medium text-zinc-700 transition hover:bg-zinc-50 hover:border-zinc-300"
                          >
                            <.icon name="hero-plus-mini" class="h-3 w-3" />
                            {section_type_label(type)}
                          </button>
                        </div>
                      </div>
                    </div>

                    <%!-- Raw HTML mode --%>
                    <div :if={@builder_mode == "html"} class="space-y-2">
                      <p class="text-xs text-zinc-500">
                        Paste a complete HTML email. Use
                        <code class="rounded bg-zinc-100 px-1 py-0.5">{"{{name}}"}</code>
                        or <code class="rounded bg-zinc-100 px-1 py-0.5">{"{{first_name}}"}</code>
                        to personalise.
                      </p>
                      <.input
                        field={@form[:body]}
                        type="textarea"
                        label="HTML email body"
                        rows="18"
                        required
                      />
                    </div>
                  </div>
                </.admin_panel>
              </.form>

              <.admin_panel
                title="Footer"
                subtitle="Shared masthead and footer settings used by every campaign email."
              >
                <.form for={@email_branding_form} phx-submit="save_email_branding" class="space-y-4">
                  <div class="space-y-3 rounded-xl border border-zinc-200 bg-zinc-50 p-4">
                    <div>
                      <p class="text-sm font-semibold text-zinc-900">Masthead image</p>
                      <p class="mt-1 text-xs text-zinc-500">
                        This logo appears first in every campaign email.
                      </p>
                    </div>

                    <div
                      :if={@email_branding_form[:masthead_logo_url].value not in [nil, ""]}
                      class="overflow-hidden rounded-lg border border-zinc-200 bg-white"
                    >
                      <img
                        src={@email_branding_form[:masthead_logo_url].value}
                        alt={@email_branding_form[:masthead_logo_alt].value || "Masthead logo"}
                        class="mx-auto max-h-40 w-full object-contain p-4"
                      />
                    </div>

                    <label class="flex cursor-pointer flex-col items-center justify-center gap-1 rounded-lg border border-dashed border-zinc-300 px-4 py-5 text-center text-sm text-zinc-600 transition hover:border-blueink hover:text-blueink">
                      <.icon name="hero-arrow-up-tray" class="h-5 w-5" />
                      <span class="font-medium">Upload masthead logo</span>
                      <span class="text-xs text-zinc-400">
                        JPG, PNG or WEBP · max {@uploads.masthead_logo.max_file_size |> div(1_000_000)}MB
                      </span>
                      <.live_file_input upload={@uploads.masthead_logo} class="sr-only" />
                    </label>

                    <p :for={entry <- @uploads.masthead_logo.entries} class="text-xs text-zinc-500">
                      Uploading {entry.client_name} — {entry.progress}%
                      <button
                        type="button"
                        phx-click="cancel_upload"
                        phx-value-upload="masthead_logo"
                        phx-value-ref={entry.ref}
                        class="ml-2 text-red-500 hover:underline"
                      >
                        cancel
                      </button>
                    </p>

                    <p
                      :for={err <- upload_errors(@uploads.masthead_logo)}
                      class="text-xs text-red-600"
                    >
                      {upload_error_to_string(err)}
                    </p>
                  </div>

                  <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <.input
                      field={@email_branding_form[:masthead_logo_url]}
                      type="text"
                      label="Masthead logo URL"
                      placeholder="/images/logo.png"
                    />
                    <.input
                      field={@email_branding_form[:masthead_logo_alt]}
                      type="text"
                      label="Masthead logo alt text"
                      placeholder="Maraga '27"
                    />
                  </div>

                  <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <.input
                      field={@email_branding_form[:footer_social_heading]}
                      type="text"
                      label="Footer social heading"
                      placeholder="Connect with us"
                    />
                    <.input
                      field={@email_branding_form[:footer_contact_name]}
                      type="text"
                      label="Footer contact name"
                      placeholder="David Maraga Campaign Headquarters"
                    />
                  </div>

                  <.input
                    field={@email_branding_form[:footer_contact_address]}
                    type="text"
                    label="Footer address"
                    placeholder="Off Vihiga Rd, Kileleshwa, Nairobi"
                  />

                  <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <.input
                      field={@email_branding_form[:footer_phone]}
                      type="text"
                      label="Footer phone"
                      placeholder="+254 746 900 027"
                    />
                    <.input
                      field={@email_branding_form[:footer_website_label]}
                      type="text"
                      label="Footer website label"
                      placeholder="DavidMaraga.info"
                    />
                  </div>

                  <.input
                    field={@email_branding_form[:footer_website_url]}
                    type="text"
                    label="Footer website URL"
                    placeholder="https://davidmaraga.info/"
                  />

                  <.input
                    field={@email_branding_form[:footer_legal_text]}
                    type="textarea"
                    label="Footer legal text"
                    rows="3"
                  />

                  <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
                    <.input
                      field={@email_branding_form[:footer_unsubscribe_label]}
                      type="text"
                      label="Unsubscribe label"
                      placeholder="Unsubscribe"
                    />
                    <.input
                      field={@email_branding_form[:footer_preferences_label]}
                      type="text"
                      label="Preferences label"
                      placeholder="Update preferences"
                    />
                    <.input
                      field={@email_branding_form[:footer_browser_label]}
                      type="text"
                      label="Browser label"
                      placeholder="View in browser"
                    />
                  </div>

                  <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
                    <.input
                      field={@email_branding_form[:footer_unsubscribe_url]}
                      type="text"
                      label="Unsubscribe URL"
                      placeholder="#"
                    />
                    <.input
                      field={@email_branding_form[:footer_preferences_url]}
                      type="text"
                      label="Preferences URL"
                      placeholder="#"
                    />
                    <.input
                      field={@email_branding_form[:footer_browser_url]}
                      type="text"
                      label="View in browser URL"
                      placeholder="#"
                    />
                  </div>

                  <div class="space-y-3 border-t border-zinc-100 pt-4">
                    <p class="text-sm font-semibold text-zinc-900">Social links</p>
                    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
                      <.input
                        field={@email_branding_form[:footer_social_x_url]}
                        type="text"
                        label="X URL"
                      />
                      <.input
                        field={@email_branding_form[:footer_social_instagram_url]}
                        type="text"
                        label="Instagram URL"
                      />
                      <.input
                        field={@email_branding_form[:footer_social_youtube_url]}
                        type="text"
                        label="YouTube URL"
                      />
                      <.input
                        field={@email_branding_form[:footer_social_facebook_url]}
                        type="text"
                        label="Facebook URL"
                      />
                      <.input
                        field={@email_branding_form[:footer_social_tiktok_url]}
                        type="text"
                        label="TikTok URL"
                      />
                    </div>
                  </div>

                  <div class="border-t border-zinc-100 pt-4">
                    <.button type="submit">Save email masthead/footer</.button>
                  </div>
                </.form>
              </.admin_panel>
            </div>
          </div>

          <div class="xl:sticky xl:top-6 xl:self-start">
            <.admin_panel
              title="Preview"
              subtitle="Pinned on the right so you can scroll the builder without losing the live render."
            >
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
                class="h-[calc(100vh-12rem)] min-h-[780px] w-full rounded-xl border border-zinc-200 bg-white"
              >
              </iframe>
            </.admin_panel>
          </div>
        </div>

        <%!-- History --%>
        <.admin_panel
          :if={@live_action == :index}
          title="Broadcasts"
          subtitle="Drafts, in-flight sends, and everything delivered."
        >
          <div :if={@campaigns != []} class="divide-y divide-zinc-100">
            <div
              :for={campaign <- @campaigns}
              class="flex flex-col gap-3 py-4 first:pt-0 last:pb-0 sm:flex-row sm:items-start sm:justify-between"
            >
              <div class="min-w-0">
                <div class="flex flex-wrap items-center gap-2">
                  <.link
                    navigate={~p"/admin/emails/#{campaign.id}"}
                    class="truncate font-medium text-zinc-900 hover:text-blueink hover:underline"
                  >
                    {campaign.subject}
                  </.link>
                  <.admin_badge tone={status_tone(campaign.status)} label={campaign.status} />
                  <.admin_badge :if={campaign.ab_test} tone="neutral" label="A/B" />
                  <.admin_badge :if={campaign.sections != []} tone="neutral" label="sections" />
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
                  :if={campaign.ab_test and campaign.status != "draft"}
                  class="mt-2 flex flex-wrap gap-2"
                >
                  <span
                    :for={variant <- ~w(A B)}
                    :if={vstats = Map.get(Map.get(@variant_stats, campaign.id, %{}), variant)}
                    class="inline-flex items-center gap-1.5 rounded-md bg-zinc-100 px-2 py-1 text-xs text-zinc-600"
                  >
                    <span class="font-semibold text-zinc-900">{variant}</span>
                    {vstats.sent}/{vstats.total} sent{if vstats.failed > 0,
                      do: " · #{vstats.failed} failed"}
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
                <.link
                  :if={campaign.status == "draft"}
                  navigate={~p"/admin/emails/#{campaign.id}"}
                  class="text-sm font-medium text-blueink hover:underline"
                >
                  Edit
                </.link>
              </div>
            </div>
          </div>

          <.admin_empty_state
            :if={@campaigns == []}
            title="No broadcasts yet"
            description="Build your first email with the section editor, send yourself a test, then send it to the volunteer database."
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
                  The list is split evenly between variant A and variant B.</span> Delivery runs in the background and can't be undone.
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

  defp assign_email_branding_form(socket) do
    defaults = NewsletterBuilder.default_branding_settings()
    settings = Content.list_settings_map("email.")

    form_data =
      Enum.reduce(@email_branding_fields, %{}, fn {field, key}, acc ->
        Map.put(acc, field, Map.get(settings, key, Map.get(defaults, key, "")))
      end)

    assign(socket, :email_branding_form, to_form(form_data, as: :email_branding))
  end

  defp email_branding_params_to_settings(params) do
    Enum.reduce(@email_branding_fields, %{}, fn {field, key}, acc ->
      Map.put(acc, key, Map.get(params, field, ""))
    end)
  end

  # Rich text editor for a section body. Unlike the blog editor (which syncs a
  # hidden form input), the section builder keeps its content outside the form,
  # so the CKEditor hook runs in "push mode": each edit is sent to the LiveView
  # as an `update_section_field` event carrying the section index and field.
  attr :id, :string, required: true
  attr :index, :integer, required: true
  attr :field, :string, default: "body"
  attr :value, :string, default: ""

  defp section_rich_text(assigns) do
    assigns = assign(assigns, :html, MaragaInfoWeb.RichText.to_editor_html(assigns.value))

    ~H"""
    <div
      id={@id}
      phx-hook="CKEditor"
      data-ck-value={@html}
      data-ck-push-event="update_section_field"
      data-ck-index={@index}
      data-ck-field={@field}
    >
      <div id={@id <> "-ck"} phx-update="ignore">
        <div data-ck-editor></div>
      </div>
    </div>
    """
  end
end
