defmodule MaragaInfoWeb.Admin.NavLinkLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfo.Content.NavLink

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Navbar")
     |> assign(:page_subtitle, "Manage the links and dropdowns shown in the public site navbar.")
     |> assign(:show_form, false)
     |> assign(:editing, nil)
     |> assign(:form, nil)
     |> load_nav_links()}
  end

  @impl true
  def handle_params(_params, url, socket) do
    {:noreply, assign(socket, :current_path, URI.parse(url).path)}
  end

  @impl true
  def handle_event("new", %{"parent_id" => parent_id}, socket) do
    nav_link = %NavLink{parent_id: parent_id}

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing, nav_link)
     |> assign_form(Content.change_nav_link(nav_link))}
  end

  def handle_event("new", _params, socket) do
    nav_link = %NavLink{}

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing, nav_link)
     |> assign_form(Content.change_nav_link(nav_link))}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    nav_link = Content.get_nav_link!(id)

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing, nav_link)
     |> assign_form(Content.change_nav_link(nav_link))}
  end

  def handle_event("close_form", _params, socket) do
    {:noreply, assign(socket, show_form: false, editing: nil, form: nil)}
  end

  def handle_event("validate", %{"nav_link" => params}, socket) do
    changeset =
      socket.assigns.editing
      |> Content.change_nav_link(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"nav_link" => params}, socket) do
    save_nav_link(socket, socket.assigns.editing, params)
  end

  def handle_event("delete", %{"id" => id}, socket) do
    id
    |> Content.get_nav_link!()
    |> Content.delete_nav_link()

    {:noreply, socket |> put_flash(:info, "Nav link deleted") |> load_nav_links()}
  end

  def handle_event("reset_to_defaults", _params, socket) do
    Content.reset_nav_links_to_defaults()

    {:noreply,
     socket |> put_flash(:info, "Navbar reset to defaults") |> load_nav_links()}
  end

  def handle_event("toggle_visible", %{"id" => id}, socket) do
    nav_link = Content.get_nav_link!(id)
    Content.update_nav_link(nav_link, %{"is_visible" => to_string(!nav_link.is_visible)})

    {:noreply, load_nav_links(socket)}
  end

  def handle_event("move", %{"id" => id, "direction" => direction}, socket) do
    id = String.to_integer(id)
    nav_link = Content.get_nav_link!(id)

    siblings =
      socket.assigns.nav_links
      |> siblings_of(nav_link)
      |> Enum.map(& &1.id)

    case reorder(siblings, id, direction) do
      ^siblings ->
        {:noreply, socket}

      reordered ->
        Content.reorder_nav_links(reordered)
        {:noreply, load_nav_links(socket)}
    end
  end

  defp siblings_of(nav_links, %NavLink{parent_id: nil}), do: nav_links

  defp siblings_of(nav_links, %NavLink{parent_id: parent_id}) do
    nav_links
    |> Enum.find(&(&1.id == parent_id))
    |> case do
      nil -> []
      parent -> parent.children
    end
  end

  defp reorder(ids, id, "up"), do: swap(ids, id, -1)
  defp reorder(ids, id, "down"), do: swap(ids, id, 1)

  defp swap(ids, id, offset) do
    index = Enum.find_index(ids, &(&1 == id))
    target = index + offset

    if index && target >= 0 && target < length(ids) do
      ids
      |> List.delete_at(index)
      |> List.insert_at(target, id)
    else
      ids
    end
  end

  defp save_nav_link(socket, %NavLink{id: nil} = nav_link, params) do
    params = Map.put(params, "position", next_position(socket, nav_link.parent_id))

    case Content.create_nav_link(params) do
      {:ok, _nav_link} ->
        {:noreply,
         socket
         |> put_flash(:info, "Nav link added")
         |> assign(show_form: false, editing: nil, form: nil)
         |> load_nav_links()}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_nav_link(socket, %NavLink{} = nav_link, params) do
    case Content.update_nav_link(nav_link, params) do
      {:ok, _nav_link} ->
        {:noreply,
         socket
         |> put_flash(:info, "Nav link updated")
         |> assign(show_form: false, editing: nil, form: nil)
         |> load_nav_links()}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp next_position(socket, nil) do
    length(socket.assigns.nav_links)
  end

  defp next_position(socket, parent_id) do
    parent_id = if is_binary(parent_id), do: String.to_integer(parent_id), else: parent_id

    socket.assigns.nav_links
    |> Enum.find(&(&1.id == parent_id))
    |> case do
      nil -> 0
      parent -> length(parent.children)
    end
  end

  defp load_nav_links(socket) do
    assign(socket, :nav_links, Content.list_nav_links())
  end

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))

  defp parent_label(nav_links, %NavLink{parent_id: nil}), do: nil

  defp parent_label(nav_links, %NavLink{parent_id: parent_id}) do
    case Enum.find(nav_links, &(&1.id == parent_id)) do
      nil -> nil
      parent -> parent.label
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
        <button
          type="button"
          phx-click="reset_to_defaults"
          data-confirm="Reset the navbar to the original defaults? This removes all custom links."
          class="inline-flex items-center gap-2 rounded-lg border border-zinc-200 px-3.5 py-2 text-sm font-medium text-zinc-700 transition hover:bg-zinc-50"
        >
          <.icon name="hero-arrow-path-mini" class="h-4 w-4" /> Reset to defaults
        </button>
        <button
          type="button"
          phx-click="new"
          class="inline-flex items-center gap-2 rounded-lg bg-blueink px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blueink/90"
        >
          <.icon name="hero-plus-mini" class="h-4 w-4" /> New link
        </button>
      </:actions>

      <.admin_panel
        title="Navbar links"
        subtitle="Top-level links appear directly in the navbar. Add children to a link to turn it into a dropdown."
      >
        <div :if={@nav_links != []} class="divide-y divide-zinc-100">
          <div :for={nav_link <- @nav_links}>
            <.nav_link_row nav_link={nav_link} depth={0} />
            <.nav_link_row :for={child <- nav_link.children} nav_link={child} depth={1} />
          </div>
        </div>

        <.admin_empty_state
          :if={@nav_links == []}
          title="No nav links yet"
          description="Add the first link to start building the public navbar."
        />
      </.admin_panel>

      <.modal :if={@show_form} id="nav-link-form-modal" show on_cancel={JS.push("close_form")}>
        <h2 class="text-lg font-semibold text-zinc-900">
          {if @editing && @editing.id, do: "Edit link", else: "New link"}
        </h2>
        <p :if={@editing && !@editing.id && @editing.parent_id} class="mt-1 text-sm text-zinc-500">
          This will appear as a dropdown item under {parent_label(@nav_links, @editing)}.
        </p>

        <.form
          for={@form}
          id="nav-link-form"
          phx-change="validate"
          phx-submit="save"
          class="mt-6 space-y-5"
        >
          <input type="hidden" name="nav_link[parent_id]" value={@editing && @editing.parent_id} />
          <.input field={@form[:label]} type="text" label="Label" />
          <.input
            field={@form[:href]}
            type="text"
            label="Link (optional)"
            placeholder="/events or https://example.com"
          />
          <.input
            :if={@editing && is_nil(@editing.parent_id)}
            field={@form[:placement]}
            type="select"
            label="Position in navbar"
            options={[{"Left of logo", "left"}, {"Right of logo", "right"}]}
          />
          <.input field={@form[:is_visible]} type="checkbox" label="Show in navbar" />

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
              Save link
            </button>
          </div>
        </.form>
      </.modal>
    </.admin_shell>
    """
  end

  attr :nav_link, :map, required: true
  attr :depth, :integer, required: true

  defp nav_link_row(assigns) do
    ~H"""
    <div class={[
      "flex flex-col gap-3 py-4 sm:flex-row sm:items-center sm:justify-between",
      @depth > 0 && "pl-8"
    ]}>
      <div class="min-w-0">
        <div class="flex items-center gap-2">
          <.icon :if={@depth > 0} name="hero-arrow-turn-down-right" class="h-3.5 w-3.5 text-zinc-400" />
          <p class="truncate text-sm font-semibold text-zinc-900">{@nav_link.label}</p>
          <.admin_badge
            :if={@depth == 0}
            tone="neutral"
            label={if @nav_link.placement == "left", do: "left", else: "right"}
          />
          <.admin_badge
            tone={if @nav_link.is_visible, do: "published", else: "draft"}
            label={if @nav_link.is_visible, do: "visible", else: "hidden"}
          />
        </div>
        <p :if={@nav_link.href} class="mt-0.5 text-xs text-zinc-500">{@nav_link.href}</p>
      </div>
      <div class="flex shrink-0 items-center gap-3 text-xs font-medium">
        <button
          type="button"
          phx-click="move"
          phx-value-id={@nav_link.id}
          phx-value-direction="up"
          aria-label="Move up"
          class="text-zinc-500 hover:text-zinc-900"
        >
          <.icon name="hero-chevron-up-mini" class="h-4 w-4" />
        </button>
        <button
          type="button"
          phx-click="move"
          phx-value-id={@nav_link.id}
          phx-value-direction="down"
          aria-label="Move down"
          class="text-zinc-500 hover:text-zinc-900"
        >
          <.icon name="hero-chevron-down-mini" class="h-4 w-4" />
        </button>
        <button
          type="button"
          phx-click="toggle_visible"
          phx-value-id={@nav_link.id}
          class="text-zinc-500 hover:underline"
        >
          {if @nav_link.is_visible, do: "Hide", else: "Show"}
        </button>
        <button
          :if={@depth == 0}
          type="button"
          phx-click="new"
          phx-value-parent_id={@nav_link.id}
          class="text-blueink hover:underline"
        >
          Add child
        </button>
        <button type="button" phx-click="edit" phx-value-id={@nav_link.id} class="text-blueink hover:underline">
          Edit
        </button>
        <button
          type="button"
          phx-click="delete"
          phx-value-id={@nav_link.id}
          data-confirm="Remove this nav link?"
          class="text-red-600 hover:underline"
        >
          Delete
        </button>
      </div>
    </div>
    """
  end
end
