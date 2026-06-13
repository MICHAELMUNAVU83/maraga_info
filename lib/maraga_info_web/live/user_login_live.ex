defmodule MaragaInfoWeb.UserLoginLive do
  use MaragaInfoWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center bg-blueink px-4 py-16">
      <div
        aria-hidden="true"
        class="pointer-events-none absolute inset-0"
        style="background-image: radial-gradient(rgba(255,255,255,0.06) 1.6px, transparent 1.7px); background-size: 24px 24px;"
      >
      </div>

      <div class="relative w-full max-w-md overflow-hidden rounded-[8px] bg-white shadow-2xl">
        <div class="flex flex-col items-center bg-crimson px-8 py-8 text-center">
          <a href="/">
            <img src="/images/logo.png" alt="David Maraga" class="h-14 w-auto" />
          </a>
          <h1 class="mt-4 font-head text-3xl uppercase tracking-[2px] text-white">
            Admin Log In
          </h1>
          <p class="mt-1 font-serifi text-sm italic text-white/80">
            Sign in to manage the site
          </p>
        </div>

        <.simple_form
          for={@form}
          id="login_form"
          action={~p"/users/log_in"}
          phx-update="ignore"
          class="px-8 py-8"
        >
          <.input field={@form[:email]} type="email" label="Email" required />
          <.input field={@form[:password]} type="password" label="Password" required />

          <:actions>
            <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
            <.link
              href={~p"/users/reset_password"}
              class="text-sm font-semibold text-blueink hover:text-crimson hover:underline"
            >
              Forgot your password?
            </.link>
          </:actions>
          <:actions>
            <button
              phx-disable-with="Logging in..."
              class="w-full rounded-[5px] bg-blueink px-6 py-3.5 font-head text-[13px] font-bold uppercase tracking-[0.2em] text-white transition hover:bg-crimson"
            >
              Log in <span aria-hidden="true">→</span>
            </button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
