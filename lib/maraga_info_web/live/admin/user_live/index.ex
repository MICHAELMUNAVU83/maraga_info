defmodule MaragaInfoWeb.Admin.UserLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Accounts
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Users")
     |> assign(:page_subtitle, "Manage admin accounts and reset user passwords.")
     |> assign(:reset_user, nil)
     |> assign(:users, Accounts.list_users())}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> assign(:current_path, URI.parse(url).path)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :reset_password, %{"id" => id}) do
    user = Accounts.get_user!(id)

    socket
    |> assign(:reset_user, user)
    |> assign_form(Accounts.change_admin_user_password(user))
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :reset_user, nil)
  end

  @impl true
  def handle_event("validate_password", %{"user" => params}, socket) do
    changeset =
      socket.assigns.reset_user
      |> Accounts.change_admin_user_password(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save_password", %{"user" => params}, socket) do
    case Accounts.admin_set_user_password(socket.assigns.reset_user, params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password updated for #{user.email}")
         |> push_patch(to: ~p"/admin/users")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/users")}
  end

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_shell
      page_title={@page_title}
      page_subtitle={@page_subtitle}
      current_user={@current_user}
      current_path={@current_path}
    >
      <.admin_panel title="All users" subtitle="Reset a user's password directly from here.">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-zinc-200 text-sm">
            <thead class="bg-zinc-50 text-left text-xs uppercase tracking-wide text-zinc-500">
              <tr>
                <th class="px-3 py-3 font-medium">Email</th>
                <th class="px-3 py-3 font-medium">Role</th>
                <th class="px-3 py-3 font-medium">Confirmed</th>
                <th class="px-3 py-3 font-medium"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-zinc-100">
              <tr :for={user <- @users}>
                <td class="px-3 py-3 align-top font-medium text-zinc-900">{user.email}</td>
                <td class="px-3 py-3 align-top text-zinc-600">
                  {if user.is_admin, do: "Admin", else: "User"}
                </td>
                <td class="px-3 py-3 align-top text-zinc-600">
                  {if user.confirmed_at, do: "Yes", else: "No"}
                </td>
                <td class="px-3 py-3 align-top text-right">
                  <.link
                    patch={~p"/admin/users/#{user.id}/reset_password"}
                    class="rounded-lg border border-zinc-200 px-3 py-1.5 text-sm font-medium text-zinc-700 transition hover:bg-zinc-50"
                  >
                    Reset password
                  </.link>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </.admin_panel>

      <.modal
        :if={@reset_user}
        id="reset-password-modal"
        show
        on_cancel={JS.push("close_modal")}
      >
        <div class="space-y-6">
          <div>
            <h2 class="text-lg font-semibold text-zinc-900">Reset password</h2>
            <p class="mt-1 text-sm text-zinc-500">
              Set a new password for <span class="font-medium">{@reset_user.email}</span>.
              The user will need to use it on their next login.
            </p>
          </div>

          <.simple_form
            for={@form}
            id="reset-password-form"
            phx-change="validate_password"
            phx-submit="save_password"
          >
            <.input field={@form[:password]} type="password" label="New password" required />
            <.input
              field={@form[:password_confirmation]}
              type="password"
              label="Confirm new password"
              required
            />

            <:actions>
              <.button phx-disable-with="Saving...">Save password</.button>
            </:actions>
          </.simple_form>
        </div>
      </.modal>
    </.admin_shell>
    """
  end
end
