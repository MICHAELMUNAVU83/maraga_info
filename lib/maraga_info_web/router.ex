defmodule MaragaInfoWeb.Router do
  use MaragaInfoWeb, :router

  import MaragaInfoWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MaragaInfoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MaragaInfoWeb do
    pipe_through :browser

    live_session :public,
      on_mount: [{MaragaInfoWeb.UserAuth, :mount_current_user}] do
      live "/", HomeLive.Index
      live "/blog/:slug", BlogLive.Show
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", MaragaInfoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:maraga_info, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MaragaInfoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", MaragaInfoWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{MaragaInfoWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", MaragaInfoWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{MaragaInfoWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/admin", MaragaInfoWeb.Admin, as: :admin do
    pipe_through [:browser, :require_admin_user]

    live_session :admin_authenticated,
      on_mount: [{MaragaInfoWeb.UserAuth, :ensure_admin}] do
      live "/", DashboardLive, :index
      live "/media", SectionLive, :media
      live "/pages", SectionLive, :pages
      live "/settings", SectionLive, :settings

      live "/blogs", PostLive.Index, :index
      live "/blogs/new", PostLive.Form, :new
      live "/blogs/:id/edit", PostLive.Form, :edit

      live "/blogs/:id", PostLive.Show, :show
    end
  end

  scope "/", MaragaInfoWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{MaragaInfoWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
