defmodule MaragaInfoWeb.Admin.PostLive.Form do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfo.Content.Post
  alias MaragaInfoWeb.Uploads

  @max_image_mb 8
  defp max_image_mb, do: @max_image_mb

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:target_section, nil)
     |> assign(:cover_url, nil)
     |> allow_upload(:cover,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: @max_image_mb * 1_000_000,
       auto_upload: true,
       progress: &handle_progress/3
     )
     |> allow_upload(:section_images,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 12,
       max_file_size: @max_image_mb * 1_000_000,
       auto_upload: true,
       progress: &handle_progress/3
     )}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> assign(:current_path, "/admin/blogs")
     |> assign(:return_to, ~p"/admin/blogs")
     |> apply_action(socket.assigns.live_action, params, url)}
  end

  defp apply_action(socket, :new, _params, _url) do
    post = %Post{sections: []}

    socket
    |> assign(:page_title, "New blog post")
    |> assign(:post, post)
    |> assign(:sections, [])
    |> assign_form(Content.change_post(post))
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    post = Content.get_post!(id)

    socket
    |> assign(:page_title, "Edit blog post")
    |> assign(:post, post)
    |> assign(:cover_url, nil)
    |> assign(:sections, Enum.map(post.sections, &to_section_map/1))
    |> assign_form(Content.change_post(post))
  end

  # --- Scalar form ---------------------------------------------------------

  @impl true
  def handle_event("validate", %{"post" => post_params} = params, socket) do
    sections = sync_section_text(socket.assigns.sections, params["sections"])

    changeset =
      socket.assigns.post
      |> Content.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:sections, sections)
     |> assign_form(changeset)}
  end

  def handle_event("save", %{"post" => post_params} = params, socket) do
    sections = sync_section_text(socket.assigns.sections, params["sections"])

    final_params =
      post_params
      |> Map.put("sections", build_section_attrs(sections))
      |> maybe_put_cover(socket.assigns.cover_url)

    save_post(socket, socket.assigns.live_action, final_params, sections)
  end

  # --- Sections ------------------------------------------------------------

  def handle_event("add_section", _params, socket) do
    section = %{heading: "", body: "", image_urls: []}
    {:noreply, assign(socket, :sections, socket.assigns.sections ++ [section])}
  end

  def handle_event("remove_section", %{"index" => index}, socket) do
    index = String.to_integer(index)
    sections = List.delete_at(socket.assigns.sections, index)
    {:noreply, assign(socket, :sections, sections)}
  end

  def handle_event("move_section", %{"index" => index, "dir" => dir}, socket) do
    index = String.to_integer(index)
    target = if dir == "up", do: index - 1, else: index + 1
    sections = socket.assigns.sections

    sections =
      if target >= 0 and target < length(sections) do
        swap(sections, index, target)
      else
        sections
      end

    {:noreply, assign(socket, :sections, sections)}
  end

  def handle_event("target_section", %{"index" => index}, socket) do
    {:noreply, assign(socket, :target_section, String.to_integer(index))}
  end

  def handle_event("remove_section_image", %{"index" => index, "url" => url}, socket) do
    index = String.to_integer(index)

    sections =
      update_section(socket.assigns.sections, index, fn section ->
        %{section | image_urls: List.delete(section.image_urls, url)}
      end)

    {:noreply, assign(socket, :sections, sections)}
  end

  def handle_event("cancel_upload", %{"upload" => name, "ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, String.to_existing_atom(name), ref)}
  end

  def handle_event("remove_cover", _params, socket) do
    {:noreply, assign(socket, :cover_url, nil)}
  end

  # --- Upload progress (auto_upload) --------------------------------------

  defp handle_progress(:cover, entry, socket) do
    if entry.done? do
      url = consume_uploaded_entry(socket, entry, fn meta -> Uploads.store_entry(meta, entry) end)

      {:noreply, assign(socket, :cover_url, url)}
    else
      {:noreply, socket}
    end
  end

  defp handle_progress(:section_images, entry, socket) do
    if entry.done? and not is_nil(socket.assigns.target_section) do
      url = consume_uploaded_entry(socket, entry, fn meta -> Uploads.store_entry(meta, entry) end)

      sections =
        update_section(socket.assigns.sections, socket.assigns.target_section, fn section ->
          %{section | image_urls: section.image_urls ++ [url]}
        end)

      {:noreply, assign(socket, :sections, sections)}
    else
      {:noreply, socket}
    end
  end

  # --- Persistence ---------------------------------------------------------

  defp save_post(socket, :new, params, sections) do
    case Content.create_post(socket.assigns.current_user, params) do
      {:ok, post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Blog post created")
         |> push_navigate(to: ~p"/admin/blogs/#{post}")}

      {:error, changeset} ->
        {:noreply, socket |> assign(:sections, sections) |> assign_form(changeset)}
    end
  end

  defp save_post(socket, :edit, params, sections) do
    case Content.update_post(socket.assigns.post, params) do
      {:ok, post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Blog post updated")
         |> push_navigate(to: ~p"/admin/blogs/#{post}")}

      {:error, changeset} ->
        {:noreply, socket |> assign(:sections, sections) |> assign_form(changeset)}
    end
  end

  # --- Helpers -------------------------------------------------------------

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))

  defp to_section_map(section) do
    %{
      heading: section.heading || "",
      body: section.body || "",
      image_urls: section.image_urls || []
    }
  end

  # Merge the latest heading/body text from the form params into the
  # assign-driven sections, keeping image_urls (managed via events) intact.
  defp sync_section_text(sections, nil), do: sections

  defp sync_section_text(sections, params) when is_map(params) do
    sections
    |> Enum.with_index()
    |> Enum.map(fn {section, index} ->
      case Map.get(params, Integer.to_string(index)) do
        %{} = fields ->
          %{
            section
            | heading: Map.get(fields, "heading", section.heading),
              body: Map.get(fields, "body", section.body)
          }

        _ ->
          section
      end
    end)
  end

  defp build_section_attrs(sections) do
    sections
    |> Enum.reject(&empty_section?/1)
    |> Enum.with_index()
    |> Enum.map(fn {section, index} ->
      %{
        "heading" => section.heading,
        "body" => section.body,
        "image_urls" => section.image_urls,
        "position" => index
      }
    end)
  end

  defp empty_section?(section) do
    blank?(section.heading) and blank?(section.body) and section.image_urls == []
  end

  defp maybe_put_cover(params, nil), do: params
  defp maybe_put_cover(params, ""), do: params
  defp maybe_put_cover(params, url), do: Map.put(params, "image_url", url)

  defp update_section(sections, index, fun) do
    List.update_at(sections, index, fun)
  end

  defp swap(list, i, j) do
    a = Enum.at(list, i)
    b = Enum.at(list, j)

    list
    |> List.replace_at(i, b)
    |> List.replace_at(j, a)
  end

  defp blank?(nil), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_), do: false

  defp current_cover(cover_url, _form) when is_binary(cover_url) and cover_url != "",
    do: cover_url

  defp current_cover(_cover_url, form), do: Phoenix.HTML.Form.input_value(form, :image_url)

  defp upload_error_to_string(:too_large), do: "File is too large (max #{@max_image_mb}MB)"
  defp upload_error_to_string(:too_many_files), do: "Too many files"
  defp upload_error_to_string(:not_accepted), do: "Unsupported file type"
  defp upload_error_to_string(_), do: "Invalid file"

  # --- Render --------------------------------------------------------------

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell
      page_title={@page_title}
      page_subtitle="Write the story, arrange sections, and upload images. Drafts stay private until published."
      current_user={@current_user}
      current_path={@current_path}
    >
      <:actions>
        <.link
          navigate={@return_to}
          class="inline-flex items-center rounded-lg border border-zinc-200 px-3.5 py-2 text-sm font-medium text-zinc-700 transition hover:bg-zinc-50"
        >
          Cancel
        </.link>
      </:actions>

      <.form for={@form} id="post-form" phx-change="validate" phx-submit="save" class="space-y-8">
        <div class="grid gap-8 lg:grid-cols-[minmax(0,1fr)_320px]">
          <div class="space-y-8">
            <.editor_card title="Basics">
              <div class="grid gap-5 sm:grid-cols-2">
                <div class="sm:col-span-2">
                  <.input field={@form[:title]} type="text" label="Title" />
                  <p :if={@form[:slug].value not in [nil, ""]} class="mt-1 text-xs text-zinc-400">
                    URL: /blog/{@form[:slug].value}
                  </p>
                </div>
                <div class="sm:col-span-2">
                  <.input
                    field={@form[:category]}
                    type="select"
                    label="Category"
                    prompt="Select a category"
                    options={Content.post_categories()}
                  />
                </div>
              </div>
            </.editor_card>

            <.editor_card
              :if={@form[:category].value == Post.newsletter_category()}
              title="Newsletter embed"
              description="Paste the Canva embed link for this newsletter. It updates live below and on the published page."
            >
              <.input
                field={@form[:canva_embed_url]}
                type="text"
                label="Canva embed link"
                placeholder="https://www.canva.com/design/.../view?embed"
              />

              <div
                :if={Post.canva_embed_src(@form[:canva_embed_url].value)}
                class="mt-4 overflow-hidden rounded-lg border border-zinc-200 bg-white"
              >
                <div class="relative w-full bg-white" style="padding-top: 141.42%;">
                  <iframe
                    src={Post.canva_embed_src(@form[:canva_embed_url].value)}
                    class="absolute inset-0 h-full w-full bg-white"
                    loading="lazy"
                    allowfullscreen
                  >
                  </iframe>
                </div>
              </div>
            </.editor_card>

            <.editor_card
              title="Sections"
              description="Build the article as a series of blocks. Each section can have a heading, text, and images."
            >
              <div
                :if={@sections == []}
                class="rounded-lg border border-dashed border-zinc-200 px-5 py-8 text-center text-sm text-zinc-500"
              >
                No sections yet. Add your first one below.
              </div>

              <div class="space-y-5">
                <div
                  :for={{section, index} <- Enum.with_index(@sections)}
                  class="rounded-xl border border-zinc-200 bg-white p-4 sm:p-5"
                >
                  <div class="mb-4 flex items-center justify-between">
                    <span class="inline-flex items-center rounded-md bg-zinc-100 px-2.5 py-1 text-xs font-semibold text-zinc-600">
                      Section {index + 1}
                    </span>
                    <div class="flex items-center gap-1">
                      <button
                        type="button"
                        phx-click="move_section"
                        phx-value-index={index}
                        phx-value-dir="up"
                        disabled={index == 0}
                        class="rounded-md p-1.5 text-zinc-500 transition hover:bg-zinc-100 disabled:opacity-30"
                        aria-label="Move section up"
                      >
                        <.icon name="hero-arrow-up-mini" class="h-4 w-4" />
                      </button>
                      <button
                        type="button"
                        phx-click="move_section"
                        phx-value-index={index}
                        phx-value-dir="down"
                        disabled={index == length(@sections) - 1}
                        class="rounded-md p-1.5 text-zinc-500 transition hover:bg-zinc-100 disabled:opacity-30"
                        aria-label="Move section down"
                      >
                        <.icon name="hero-arrow-down-mini" class="h-4 w-4" />
                      </button>
                      <button
                        type="button"
                        phx-click="remove_section"
                        phx-value-index={index}
                        data-confirm="Remove this section?"
                        class="rounded-md p-1.5 text-zinc-500 transition hover:bg-red-50 hover:text-red-600"
                        aria-label="Remove section"
                      >
                        <.icon name="hero-trash-mini" class="h-4 w-4" />
                      </button>
                    </div>
                  </div>

                  <div class="space-y-4">
                    <input
                      type="text"
                      name={"sections[#{index}][heading]"}
                      value={section.heading}
                      phx-debounce="blur"
                      placeholder="Section heading (optional)"
                      class="block w-full rounded-lg border-zinc-300 text-sm font-semibold text-zinc-900 focus:border-blueink focus:ring-blueink"
                    />
                    <.rich_text_area
                      id={"rt-section-#{index}"}
                      name={"sections[#{index}][body]"}
                      value={section.body}
                      rows="4"
                      placeholder="Section text. Separate paragraphs with a blank line."
                    />

                    <div :if={section.image_urls != []} class="grid grid-cols-3 gap-3 sm:grid-cols-4">
                      <div
                        :for={url <- section.image_urls}
                        class="group relative overflow-hidden rounded-lg border border-zinc-200"
                      >
                        <img src={url} class="aspect-square w-full object-cover" />
                        <button
                          type="button"
                          phx-click="remove_section_image"
                          phx-value-index={index}
                          phx-value-url={url}
                          class="absolute right-1 top-1 rounded-md bg-white/90 p-1 text-zinc-700 opacity-0 shadow-sm transition group-hover:opacity-100 hover:text-red-600"
                          aria-label="Remove image"
                        >
                          <.icon name="hero-x-mark-mini" class="h-4 w-4" />
                        </button>
                      </div>
                    </div>

                    <label
                      phx-click="target_section"
                      phx-value-index={index}
                      class="flex cursor-pointer items-center justify-center gap-2 rounded-lg border border-dashed border-zinc-300 px-4 py-3 text-sm font-medium text-zinc-600 transition hover:border-blueink hover:text-blueink"
                    >
                      <.icon name="hero-photo" class="h-5 w-5" /> Add images to this section
                      <.live_file_input upload={@uploads.section_images} class="sr-only" />
                    </label>

                    <div
                      :for={entry <- entries_for(@uploads.section_images, @target_section, index)}
                      class="flex items-center gap-3 text-xs text-zinc-500"
                    >
                      <span class="truncate">{entry.client_name}</span>
                      <span>{entry.progress}%</span>
                    </div>
                  </div>
                </div>
              </div>

              <button
                type="button"
                phx-click="add_section"
                class="mt-5 inline-flex items-center gap-2 rounded-lg border border-zinc-300 px-4 py-2.5 text-sm font-medium text-zinc-700 transition hover:border-blueink hover:text-blueink"
              >
                <.icon name="hero-plus-mini" class="h-4 w-4" /> Add section
              </button>
            </.editor_card>

            <.editor_card
              title="Fallback body"
              description="Optional. Used only for posts without sections. Separate paragraphs with a blank line."
            >
              <.rich_text_area
                id="rt-body"
                name="post[body]"
                value={@form[:body].value}
                rows="5"
                label="Body"
                placeholder="Separate paragraphs with a blank line."
              />
            </.editor_card>
          </div>

          <div class="space-y-8">
            <.editor_card title="Publish">
              <div class="space-y-5">
                <.input
                  field={@form[:status]}
                  type="select"
                  label="Status"
                  options={[{"Draft", "draft"}, {"Published", "published"}]}
                />
                <.input field={@form[:published_at]} type="datetime-local" label="Published at" />
                <.input field={@form[:is_featured]} type="checkbox" label="Feature on homepage" />
              </div>
            </.editor_card>

            <.editor_card title="Cover image">
              <div class="space-y-4">
                <div
                  :if={current_cover(@cover_url, @form)}
                  class="overflow-hidden rounded-lg border border-zinc-200"
                >
                  <img
                    src={current_cover(@cover_url, @form)}
                    class="aspect-video w-full object-cover object-top"
                  />
                </div>

                <label class="flex cursor-pointer flex-col items-center justify-center gap-1 rounded-lg border border-dashed border-zinc-300 px-4 py-6 text-center text-sm text-zinc-600 transition hover:border-blueink hover:text-blueink">
                  <.icon name="hero-arrow-up-tray" class="h-5 w-5" />
                  <span class="font-medium">Upload cover</span>
                  <span class="text-xs text-zinc-400">JPG, PNG or WEBP up to {max_image_mb()}MB</span>
                  <.live_file_input upload={@uploads.cover} class="sr-only" />
                </label>

                <p :for={entry <- @uploads.cover.entries} class="text-xs text-zinc-500">
                  Uploading {entry.client_name} — {entry.progress}%
                </p>

                <p :for={err <- cover_errors(@uploads.cover)} class="text-xs text-red-600">
                  {upload_error_to_string(err)}
                </p>

                <p :if={@form[:image_url].errors != []} class="text-xs text-red-600">
                  A cover image is required.
                </p>
              </div>
            </.editor_card>

            <.editor_card title="SEO">
              <.input
                field={@form[:seo_description]}
                type="textarea"
                label="Search description (optional)"
                rows="3"
              />
            </.editor_card>
          </div>
        </div>

        <div class="sticky bottom-0 -mx-6 flex items-center justify-end gap-3 border-t border-zinc-200 bg-white/95 px-6 py-4 backdrop-blur sm:-mx-8 sm:px-8">
          <.link
            navigate={@return_to}
            class="rounded-lg px-4 py-2.5 text-sm font-medium text-zinc-600 transition hover:text-zinc-900"
          >
            Cancel
          </.link>
          <button
            type="submit"
            phx-disable-with="Saving..."
            class="rounded-lg bg-blueink px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-blueink/90"
          >
            Save post
          </button>
        </div>
      </.form>
    </.admin_shell>
    """
  end

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :value, :string, default: ""
  attr :rows, :string, default: "4"
  attr :placeholder, :string, default: nil
  attr :label, :string, default: nil

  defp rich_text_area(assigns) do
    ~H"""
    <div>
      <label :if={@label} class="mb-1 block text-sm font-medium text-zinc-700">{@label}</label>
      <div
        id={@id}
        phx-hook="RichTextEditor"
        class="overflow-hidden rounded-lg border border-zinc-300 focus-within:border-blueink focus-within:ring-1 focus-within:ring-blueink"
      >
        <div class="flex flex-wrap items-center gap-1 border-b border-zinc-200 bg-zinc-50 px-2 py-1.5">
          <.rt_button cmd="bold" label="Bold">
            <span class="font-bold">B</span>
          </.rt_button>
          <.rt_button cmd="italic" label="Italic">
            <span class="italic">I</span>
          </.rt_button>
          <.rt_button cmd="underline" label="Underline">
            <span class="underline">U</span>
          </.rt_button>
          <span class="mx-1 h-5 w-px bg-zinc-300"></span>
          <.rt_button cmd="undo" label="Undo">
            <.icon name="hero-arrow-uturn-left-mini" class="h-4 w-4" />
          </.rt_button>
          <.rt_button cmd="redo" label="Redo">
            <.icon name="hero-arrow-uturn-right-mini" class="h-4 w-4" />
          </.rt_button>
        </div>
        <textarea
          name={@name}
          rows={@rows}
          phx-debounce="blur"
          placeholder={@placeholder}
          class="block w-full border-0 text-sm text-zinc-700 focus:ring-0"
        >{@value}</textarea>
      </div>
    </div>
    """
  end

  attr :cmd, :string, required: true
  attr :label, :string, required: true
  slot :inner_block, required: true

  defp rt_button(assigns) do
    ~H"""
    <button
      type="button"
      data-rt-cmd={@cmd}
      title={@label}
      aria-label={@label}
      class="flex h-7 min-w-7 items-center justify-center rounded px-1.5 text-sm text-zinc-700 transition hover:bg-zinc-200"
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, default: nil
  slot :inner_block, required: true

  defp editor_card(assigns) do
    ~H"""
    <section class="rounded-xl border border-zinc-200 bg-white p-5 sm:p-6">
      <div class="mb-5">
        <h2 class="text-base font-semibold text-zinc-900">{@title}</h2>
        <p :if={@description} class="mt-1 text-sm text-zinc-500">{@description}</p>
      </div>
      {render_slot(@inner_block)}
    </section>
    """
  end

  defp entries_for(upload, target_section, index) when target_section == index, do: upload.entries
  defp entries_for(_upload, _target, _index), do: []

  defp cover_errors(upload) do
    Enum.flat_map(upload.entries, fn entry ->
      Enum.map(upload_errors(upload, entry), & &1)
    end) ++ Enum.map(upload_errors(upload), & &1)
  end
end
