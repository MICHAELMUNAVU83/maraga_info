defmodule MaragaInfoWeb.Admin.HomePageLive do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfoWeb.Uploads

  @max_image_mb 8
  @max_hero_images 8

  # Ordered list of {form_field_name, settings_key, section} tuples. Each
  # section renders as its own independent <form> with its own Save button,
  # so saving one section can't clobber another and a validation issue in one
  # panel can't block the rest of the page.
  @field_keys [
    # Hero
    {"hero_interval_seconds", "home.hero.interval_seconds", :hero},
    {"hero_title", "home.hero.title", :hero},
    {"hero_tagline", "home.hero.tagline", :hero},
    {"hero_cta1_label", "home.hero.cta1_label", :hero},
    {"hero_cta1_href", "home.hero.cta1_href", :hero},
    {"hero_cta2_label", "home.hero.cta2_label", :hero},
    {"hero_cta2_href", "home.hero.cta2_href", :hero},
    # Donate
    {"donate_button_url", "home.donate.button_url", :donate},
    {"donate_volunteer_url", "home.donate.volunteer_url", :donate},
    # Upcoming events
    {"events_title_prefix", "home.events.title_prefix", :events},
    {"events_title_accent", "home.events.title_accent", :events},
    {"events_description", "home.events.description", :events},
    # Mission
    {"mission_image", "home.mission.image", :mission},
    {"mission_heading_prefix", "home.mission.heading_prefix", :mission},
    {"mission_heading_accent1", "home.mission.heading_accent1", :mission},
    {"mission_heading_mid", "home.mission.heading_mid", :mission},
    {"mission_heading_accent2", "home.mission.heading_accent2", :mission},
    {"mission_quote", "home.mission.quote", :mission},
    {"mission_cta_href", "home.mission.cta_href", :mission},
    # Documentary
    {"documentary_title_prefix", "home.documentary.title_prefix", :documentary},
    {"documentary_title_accent", "home.documentary.title_accent", :documentary},
    {"documentary_description", "home.documentary.description", :documentary},
    {"documentary_youtube_url", "home.documentary.youtube_url", :documentary},
    # News
    {"news_title_prefix", "home.news.title_prefix", :news},
    {"news_title_accent", "home.news.title_accent", :news},
    {"news_description", "home.news.description", :news},
    # Newsletter
    {"newsletter_bg_image", "home.newsletter.bg_image", :newsletter},
    {"newsletter_eyebrow", "home.newsletter.eyebrow", :newsletter},
    {"newsletter_heading", "home.newsletter.heading", :newsletter},
    {"newsletter_description", "home.newsletter.description", :newsletter},
    {"newsletter_cta_href", "home.newsletter.cta_href", :newsletter},
    # Stats banner
    {"stats_eyebrow", "home.stats.eyebrow", :stats},
    {"stats_heading", "home.stats.heading", :stats},
    {"stats_tagline", "home.stats.tagline", :stats},
    {"stats_motto", "home.stats.motto", :stats},
    {"stats_stat1_value", "home.stats.stat1_value", :stats},
    {"stats_stat1_label", "home.stats.stat1_label", :stats},
    {"stats_stat1_description", "home.stats.stat1_description", :stats},
    {"stats_stat2_value", "home.stats.stat2_value", :stats},
    {"stats_stat2_label", "home.stats.stat2_label", :stats},
    {"stats_stat2_description", "home.stats.stat2_description", :stats},
    {"stats_stat2_badge", "home.stats.stat2_badge", :stats},
    {"stats_stat3_value", "home.stats.stat3_value", :stats},
    {"stats_stat3_label", "home.stats.stat3_label", :stats},
    {"stats_stat3_description", "home.stats.stat3_description", :stats},
    {"stats_stat4_value", "home.stats.stat4_value", :stats},
    {"stats_stat4_label", "home.stats.stat4_label", :stats},
    {"stats_stat4_description", "home.stats.stat4_description", :stats},
    # Campaign videos
    {"agenda_title_prefix", "home.agenda.title_prefix", :agenda},
    {"agenda_title_accent", "home.agenda.title_accent", :agenda},
    {"agenda_description", "home.agenda.description", :agenda}
  ]

  # Upload slot → {form_field, settings_key}
  @image_uploads %{
    mission_image: {"mission_image", "home.mission.image"},
    newsletter_bg: {"newsletter_bg_image", "home.newsletter.bg_image"}
  }

  @impl true
  def mount(_params, _session, socket) do
    settings = Content.list_settings_map("home.")

    form_data =
      Enum.reduce(@field_keys, %{}, fn {field, key, _section}, acc ->
        Map.put(acc, field, Map.get(settings, key, ""))
      end)

    socket =
      socket
      |> assign(:page_title, "Home Page")
      |> assign(:page_subtitle, "Edit all content shown on the public landing page.")
      |> assign(:form_data, form_data)
      |> assign(:form, to_form(form_data, as: :content))
      |> assign(:hero_images, hero_images_from_settings(settings))
      |> allow_upload(:hero_bg,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: @max_hero_images,
        max_file_size: @max_image_mb * 1_000_000,
        auto_upload: true,
        progress: &handle_progress/3
      )
      |> allow_upload(:mission_image,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        max_file_size: @max_image_mb * 1_000_000,
        auto_upload: true,
        progress: &handle_progress/3
      )
      |> allow_upload(:newsletter_bg,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        max_file_size: @max_image_mb * 1_000_000,
        auto_upload: true,
        progress: &handle_progress/3
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, url, socket) do
    {:noreply, assign(socket, :current_path, URI.parse(url).path)}
  end

  @impl true
  def handle_event("save", %{"content" => params}, socket) do
    section = String.to_existing_atom(Map.fetch!(params, "_section"))

    settings_map =
      @field_keys
      |> Enum.filter(fn {_field, _key, field_section} -> field_section == section end)
      |> Enum.reduce(%{}, fn {field, key, _section}, acc ->
        Map.put(acc, key, Map.get(params, field, ""))
      end)

    Content.upsert_settings(settings_map)

    {:noreply, put_flash(socket, :info, "Section saved.")}
  end

  # Required so the browser sends file-selection changes over the socket —
  # that's what drives the auto_upload progress callbacks below. No form
  # validation happens here since these sections have no changeset.
  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def handle_event("cancel_upload", %{"upload" => name, "ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, String.to_existing_atom(name), ref)}
  end

  def handle_event("remove_hero_image", %{"url" => url}, socket) do
    hero_images = List.delete(socket.assigns.hero_images, url)

    Content.upsert_settings(%{"home.hero.bg_images" => Jason.encode!(hero_images)})

    {:noreply, assign(socket, :hero_images, hero_images)}
  end

  # Auto-upload progress callbacks — store the file as soon as it finishes and
  # immediately persist the new URL so it survives a page refresh even if the
  # user never clicks Save.
  defp handle_progress(:hero_bg, entry, socket) do
    if entry.done? do
      url = consume_uploaded_entry(socket, entry, fn meta -> Uploads.store_entry(meta, entry) end)
      hero_images = socket.assigns.hero_images ++ [url]

      Content.upsert_settings(%{"home.hero.bg_images" => Jason.encode!(hero_images)})

      {:noreply, assign(socket, :hero_images, hero_images)}
    else
      {:noreply, socket}
    end
  end

  defp handle_progress(slot, entry, socket)
       when slot in [:mission_image, :newsletter_bg] do
    if entry.done? do
      url = consume_uploaded_entry(socket, entry, fn meta -> Uploads.store_entry(meta, entry) end)
      {field, key} = Map.fetch!(@image_uploads, slot)

      Content.upsert_settings(%{key => url})

      form_data = Map.put(socket.assigns.form_data, field, url)

      {:noreply,
       socket
       |> assign(:form_data, form_data)
       |> assign(:form, to_form(form_data, as: :content))}
    else
      {:noreply, socket}
    end
  end

  # Mirrors HomeLive.Index's hero image fallback: a JSON list under
  # "home.hero.bg_images" if present, otherwise the legacy single
  # "home.hero.bg_image" setting, otherwise no images.
  defp hero_images_from_settings(settings) do
    case Map.get(settings, "home.hero.bg_images") do
      json when is_binary(json) and json != "" ->
        case Jason.decode(json) do
          {:ok, images} when is_list(images) -> images
          _ -> []
        end

      _ ->
        case Map.get(settings, "home.hero.bg_image") do
          url when is_binary(url) and url != "" -> [url]
          _ -> []
        end
    end
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
        <a
          href="/"
          target="_blank"
          rel="noopener"
          class="inline-flex items-center gap-1.5 rounded-lg border border-zinc-300 bg-white px-3 py-1.5 text-sm font-medium text-zinc-700 transition hover:bg-zinc-50"
        >
          Preview site <.icon name="hero-arrow-top-right-on-square-mini" class="h-4 w-4" />
        </a>
      </:actions>

      <div class="space-y-6">
        <%!-- Hero --%>
        <.admin_panel
          title="Hero"
          subtitle="Background image slideshow, headline, tagline, and CTA buttons."
        >
          <.form
            for={@form}
            id="home-form-hero"
            phx-change="validate"
            phx-submit="save"
            class="space-y-4"
          >
            <input type="hidden" name="content[_section]" value="hero" />
            <.hero_images_field hero_images={@hero_images} upload={@uploads.hero_bg} />
            <.input
              field={@form[:hero_interval_seconds]}
              type="number"
              min="2"
              label="Slide duration (seconds)"
              placeholder="6"
            />
            <.input
              field={@form[:hero_title]}
              label="Main Title"
              placeholder="David Kenani Maraga - 2027"
            />
            <.input
              field={@form[:hero_tagline]}
              label="Tagline"
              placeholder="Reset. Restore. Rebuild Kenya."
            />
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <.input
                field={@form[:hero_cta1_label]}
                label="Primary Button — Label"
                placeholder="Read More"
              />
              <.input
                field={@form[:hero_cta1_href]}
                label="Primary Button — Link"
                placeholder="#mission"
              />
            </div>
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <.input
                field={@form[:hero_cta2_label]}
                label="Secondary Button — Label"
                placeholder="Jiandikishe Kupiga Kura"
              />
              <.input
                field={@form[:hero_cta2_href]}
                label="Secondary Button — Link"
                placeholder="https://www.iebc.or.ke/..."
              />
            </div>
            <.save_button />
          </.form>
        </.admin_panel>

        <%!-- Donate --%>
        <.admin_panel title="Donate" subtitle="Donation and volunteer action URLs.">
          <.form for={@form} id="home-form-donate" phx-submit="save" class="space-y-4">
            <input type="hidden" name="content[_section]" value="donate" />
            <.input
              field={@form[:donate_button_url]}
              label="Donate Now URL"
              placeholder="https://donations.davidmaraga.com/"
            />
            <.input
              field={@form[:donate_volunteer_url]}
              label="Volunteer URL"
              placeholder="https://www.davidmaraga.com/volunteer"
            />
            <.save_button />
          </.form>
        </.admin_panel>

        <%!-- Upcoming Events --%>
        <.admin_panel
          title="Upcoming Events"
          subtitle="Section heading and description for the events grid."
        >
          <.form for={@form} id="home-form-events" phx-submit="save" class="space-y-4">
            <input type="hidden" name="content[_section]" value="events" />
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <.input
                field={@form[:events_title_prefix]}
                label="Section Title — prefix"
                placeholder="Upcoming"
              />
              <.input
                field={@form[:events_title_accent]}
                label="Section Title — accent word"
                placeholder="Events"
              />
            </div>
            <.input
              field={@form[:events_description]}
              label="Description"
              placeholder="Follow the latest news and updates from the campaign trail."
            />
            <.save_button />
          </.form>
        </.admin_panel>

        <%!-- Mission --%>
        <.admin_panel
          title="Mission"
          subtitle="Side photo, heading with accent words, quote, and bio link."
        >
          <.form
            for={@form}
            id="home-form-mission"
            phx-change="validate"
            phx-submit="save"
            class="space-y-4"
          >
            <input type="hidden" name="content[_section]" value="mission" />
            <.image_field
              label="Side Photo"
              field={@form[:mission_image]}
              upload={@uploads.mission_image}
              upload_name="mission_image"
            />
            <p class="text-sm text-zinc-500">
              The heading is assembled from four parts — two plain segments and two gold accent words:
            </p>
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <.input
                field={@form[:mission_heading_prefix]}
                label="Heading — before first accent"
                placeholder="A man of"
              />
              <.input
                field={@form[:mission_heading_accent1]}
                label="First accent word"
                placeholder="integrity"
              />
              <.input
                field={@form[:mission_heading_mid]}
                label="Heading — middle text"
                placeholder="for a time that demands"
              />
              <.input
                field={@form[:mission_heading_accent2]}
                label="Second accent word"
                placeholder="character."
              />
            </div>
            <.input
              field={@form[:mission_quote]}
              type="textarea"
              label="Quote"
              rows="4"
              placeholder="David Maraga — the judge who annulled a presidential election..."
            />
            <.input field={@form[:mission_cta_href]} label="Bio Link" placeholder="#footer" />
            <.save_button />
          </.form>
        </.admin_panel>

        <%!-- Documentary --%>
        <.admin_panel
          title="Documentary"
          subtitle="Section heading, description, and YouTube embed URL."
        >
          <.form for={@form} id="home-form-documentary" phx-submit="save" class="space-y-4">
            <input type="hidden" name="content[_section]" value="documentary" />
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <.input
                field={@form[:documentary_title_prefix]}
                label="Section Title — prefix"
                placeholder="The Maraga Story"
              />
              <.input
                field={@form[:documentary_title_accent]}
                label="Section Title — accent word"
                placeholder="Documentary"
              />
            </div>
            <.input
              field={@form[:documentary_description]}
              label="Description"
              placeholder="The first autobiographical documentary on David Maraga, produced with NTV."
            />
            <.input
              field={@form[:documentary_youtube_url]}
              label="YouTube Embed URL"
              placeholder="https://www.youtube.com/embed/-2QefPbyXrQ"
            />
            <.save_button />
          </.form>
        </.admin_panel>

        <%!-- News --%>
        <.admin_panel
          title="News"
          subtitle="Section heading and description for the latest news grid."
        >
          <.form for={@form} id="home-form-news" phx-submit="save" class="space-y-4">
            <input type="hidden" name="content[_section]" value="news" />
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <.input
                field={@form[:news_title_prefix]}
                label="Section Title — prefix"
                placeholder="latest"
              />
              <.input
                field={@form[:news_title_accent]}
                label="Section Title — accent word"
                placeholder="News"
              />
            </div>
            <.input
              field={@form[:news_description]}
              label="Description"
              placeholder="Get the latest updates on the campaign trail, policy positions, and more."
            />
            <.save_button />
          </.form>
        </.admin_panel>

        <%!-- Newsletter --%>
        <.admin_panel
          title="Newsletter"
          subtitle="Background image, heading, description, and subscribe button."
        >
          <.form
            for={@form}
            id="home-form-newsletter"
            phx-change="validate"
            phx-submit="save"
            class="space-y-4"
          >
            <input type="hidden" name="content[_section]" value="newsletter" />
            <.image_field
              label="Background Image"
              field={@form[:newsletter_bg_image]}
              upload={@uploads.newsletter_bg}
              upload_name="newsletter_bg"
            />
            <.input
              field={@form[:newsletter_eyebrow]}
              label="Eyebrow (small italic text above heading)"
              placeholder="Stay in the loop"
            />
            <.input
              field={@form[:newsletter_heading]}
              label="Heading"
              placeholder="Subscribe to the newsletter"
            />
            <.input
              field={@form[:newsletter_description]}
              type="textarea"
              label="Description"
              rows="3"
              placeholder="Get campaign updates, rally announcements, and policy highlights..."
            />
            <.input
              field={@form[:newsletter_cta_href]}
              label="Subscribe Button Link"
              placeholder="#footer"
            />
            <.save_button />
          </.form>
        </.admin_panel>

        <%!-- Stats banner --%>
        <.admin_panel
          title="Stats Banner"
          subtitle="Kenya 2027 banner — eyebrow, name, tagline, motto, and four stat cards."
        >
          <.form for={@form} id="home-form-stats" phx-submit="save" class="space-y-4">
            <input type="hidden" name="content[_section]" value="stats" />
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <.input field={@form[:stats_eyebrow]} label="Eyebrow" placeholder="Kenya 2027" />
              <.input field={@form[:stats_heading]} label="Heading" placeholder="David Maraga" />
            </div>
            <.input
              field={@form[:stats_tagline]}
              label="Tagline"
              placeholder="For President · Integrity · Justice"
            />
            <.input
              field={@form[:stats_motto]}
              label="Motto (bottom)"
              placeholder="Ukatiba Ndio Tiba"
            />

            <div class="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2">
              <div class="space-y-3 rounded-lg border border-zinc-200 p-4">
                <p class="text-xs font-semibold uppercase tracking-wide text-zinc-400">Stat 1</p>
                <.input field={@form[:stats_stat1_value]} label="Value" placeholder="1,250" />
                <.input field={@form[:stats_stat1_label]} label="Label" placeholder="Judgments" />
                <.input
                  field={@form[:stats_stat1_description]}
                  label="Description"
                  placeholder="Decisions that shaped Kenya's law"
                />
              </div>
              <div class="space-y-3 rounded-lg border border-zinc-200 p-4">
                <p class="text-xs font-semibold uppercase tracking-wide text-zinc-400">Stat 2</p>
                <.input field={@form[:stats_stat2_value]} label="Value" placeholder="#1" />
                <.input field={@form[:stats_stat2_label]} label="Label" placeholder="In Africa" />
                <.input
                  field={@form[:stats_stat2_description]}
                  label="Description"
                  placeholder="Annulled a presidential election"
                />
                <.input
                  field={@form[:stats_stat2_badge]}
                  label="Badge (optional)"
                  placeholder="Historic First"
                />
              </div>
              <div class="space-y-3 rounded-lg border border-zinc-200 p-4">
                <p class="text-xs font-semibold uppercase tracking-wide text-zinc-400">Stat 3</p>
                <.input field={@form[:stats_stat3_value]} label="Value" placeholder="47" />
                <.input field={@form[:stats_stat3_label]} label="Label" placeholder="Counties" />
                <.input
                  field={@form[:stats_stat3_description]}
                  label="Description"
                  placeholder="Justice delivered to every corner"
                />
              </div>
              <div class="space-y-3 rounded-lg border border-zinc-200 p-4">
                <p class="text-xs font-semibold uppercase tracking-wide text-zinc-400">Stat 4</p>
                <.input field={@form[:stats_stat4_value]} label="Value" placeholder="0" />
                <.input field={@form[:stats_stat4_label]} label="Label" placeholder="Tolerance" />
                <.input
                  field={@form[:stats_stat4_description]}
                  label="Description"
                  placeholder="For corruption & impunity"
                />
              </div>
            </div>
            <.save_button />
          </.form>
        </.admin_panel>

        <%!-- Campaign Videos --%>
        <.admin_panel
          title="Campaign Videos"
          subtitle="Section heading and description for the video carousel."
        >
          <.form for={@form} id="home-form-agenda" phx-submit="save" class="space-y-4">
            <input type="hidden" name="content[_section]" value="agenda" />
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <.input
                field={@form[:agenda_title_prefix]}
                label="Section Title — prefix"
                placeholder="Watch the"
              />
              <.input
                field={@form[:agenda_title_accent]}
                label="Section Title — accent word"
                placeholder="Campaign"
              />
            </div>
            <.input
              field={@form[:agenda_description]}
              label="Description"
              placeholder="Catch the latest moments from the trail..."
            />
            <.save_button />
          </.form>
        </.admin_panel>
      </div>
    </.admin_shell>
    """
  end

  defp save_button(assigns) do
    ~H"""
    <div class="flex justify-end">
      <button
        type="submit"
        class="rounded-lg bg-blueink px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-blueink/90"
      >
        Save section
      </button>
    </div>
    """
  end

  # Hero image field: multi-file upload zone + a grid of the current slideshow
  # images, each removable individually. Persisted immediately on
  # upload/removal rather than on form submit.
  attr :hero_images, :list, required: true
  attr :upload, :map, required: true

  defp hero_images_field(assigns) do
    ~H"""
    <div>
      <label class="mb-1.5 block text-sm font-medium leading-6 text-zinc-800">
        Background Images (slideshow)
      </label>

      <div :if={@hero_images != []} class="mb-3 grid grid-cols-2 gap-3 sm:grid-cols-4">
        <div :for={url <- @hero_images} class="group relative overflow-hidden rounded-lg border border-zinc-200 bg-zinc-50">
          <img src={url} alt="Hero slide" class="h-28 w-full object-cover" />
          <button
            type="button"
            phx-click="remove_hero_image"
            phx-value-url={url}
            class="absolute right-1 top-1 flex h-6 w-6 items-center justify-center rounded-full bg-white/90 text-red-500 shadow transition hover:bg-red-500 hover:text-white"
            aria-label="Remove image"
          >
            <.icon name="hero-x-mark-mini" class="h-4 w-4" />
          </button>
        </div>
      </div>

      <label class="flex cursor-pointer flex-col items-center justify-center gap-1 rounded-lg border border-dashed border-zinc-300 px-4 py-5 text-center text-sm text-zinc-600 transition hover:border-blueink hover:text-blueink">
        <.icon name="hero-arrow-up-tray" class="h-5 w-5" />
        <span class="font-medium">Add photo(s)</span>
        <span class="text-xs text-zinc-400">
          JPG, PNG or WEBP · max {@upload.max_file_size |> div(1_000_000)}MB each · up to {@upload.max_entries} at a time
        </span>
        <.live_file_input upload={@upload} class="sr-only" />
      </label>

      <p :for={entry <- @upload.entries} class="mt-1.5 text-xs text-zinc-500">
        Uploading {entry.client_name} — {entry.progress}%
        <button
          type="button"
          phx-click="cancel_upload"
          phx-value-upload="hero_bg"
          phx-value-ref={entry.ref}
          class="ml-2 text-red-500 hover:underline"
        >
          cancel
        </button>
      </p>

      <p :for={err <- upload_errors(@upload)} class="mt-1 text-xs text-red-600">
        {upload_error_to_string(err)}
      </p>
    </div>
    """
  end

  # Image field: upload zone + current preview + hidden URL input that is kept
  # in sync so the value is always submitted with the form.
  attr :label, :string, required: true
  attr :field, Phoenix.HTML.FormField, required: true
  attr :upload, :map, required: true
  attr :upload_name, :string, required: true

  defp image_field(assigns) do
    ~H"""
    <div>
      <label class="mb-1.5 block text-sm font-medium leading-6 text-zinc-800">{@label}</label>

      <%!-- Current image preview --%>
      <div
        :if={@field.value not in [nil, ""]}
        class="mb-3 overflow-hidden rounded-lg border border-zinc-200 bg-zinc-50"
      >
        <img src={@field.value} alt={@label} class="mx-auto max-h-[420px] w-full object-contain" />
      </div>

      <%!-- Drop zone / pick button --%>
      <label class="flex cursor-pointer flex-col items-center justify-center gap-1 rounded-lg border border-dashed border-zinc-300 px-4 py-5 text-center text-sm text-zinc-600 transition hover:border-blueink hover:text-blueink">
        <.icon name="hero-arrow-up-tray" class="h-5 w-5" />
        <span class="font-medium">Upload photo</span>
        <span class="text-xs text-zinc-400">
          JPG, PNG or WEBP · max {@upload.max_file_size |> div(1_000_000)}MB
        </span>
        <.live_file_input upload={@upload} class="sr-only" />
      </label>

      <%!-- Upload progress --%>
      <p :for={entry <- @upload.entries} class="mt-1.5 text-xs text-zinc-500">
        Uploading {entry.client_name} — {entry.progress}%
        <button
          type="button"
          phx-click="cancel_upload"
          phx-value-upload={@upload_name}
          phx-value-ref={entry.ref}
          class="ml-2 text-red-500 hover:underline"
        >
          cancel
        </button>
      </p>

      <%!-- Upload errors --%>
      <p :for={err <- upload_errors(@upload)} class="mt-1 text-xs text-red-600">
        {upload_error_to_string(err)}
      </p>

      <%!-- Manual URL fallback — hidden behind a disclosure so it doesn't clutter the UI --%>
      <details class="mt-2">
        <summary class="cursor-pointer text-xs text-zinc-400 hover:text-zinc-600">
          Or enter a URL manually
        </summary>
        <div class="mt-2">
          <.input field={@field} label="" placeholder="/uploads/... or https://..." />
        </div>
      </details>
    </div>
    """
  end

  defp upload_error_to_string(:too_large),
    do: "File is too large (max #{@max_image_mb}MB)"

  defp upload_error_to_string(:not_accepted),
    do: "Unsupported format — use JPG, PNG or WEBP"

  defp upload_error_to_string(:too_many_files), do: "Too many files selected at once"
  defp upload_error_to_string(_), do: "Upload failed — please try again"
end
