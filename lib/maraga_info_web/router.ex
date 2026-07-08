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

  # Admin-only JSON endpoints (e.g. inline editor image uploads). Keeps CSRF
  # protection while negotiating JSON instead of HTML.
  pipeline :admin_api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :fetch_current_user
  end

  scope "/", MaragaInfoWeb do
    pipe_through :browser

    live_session :public,
      on_mount: [{MaragaInfoWeb.UserAuth, :mount_current_user}] do
      live "/", HomeLive.Index
      live "/david-maraga", DavidMaragaLive.Index
      live "/ugm-party", UgmPartyLive.Index
      live "/campaign-pillars", CampaignPillarsLive.Index
      live "/news", NewsLive.Index
      live "/events", EventsLive.Index
      live "/newsletters", NewslettersLive.Index
      live "/press-releases", PressReleasesLive.Index
      live "/media-invitations", PressReleasesLive.Index
      live "/media/photos", MediaLive.Index
      live "/media/videos", MediaLive.Index
      live "/media", MediaLive.Index
      live "/blog", BlogLive.Index
      live "/blog/:slug", BlogLive.Show
    end
  end

  scope "/admin", MaragaInfoWeb do
    pipe_through [:admin_api, :require_admin_user]

    post "/uploads/image", UploadController, :image
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
      live "/posts", PostLive.Index, :index
      live "/posts/new", PostLive.Form, :new
      live "/posts/:id/edit", PostLive.Form, :edit
      live "/posts/:id", PostLive.Show, :show

      live "/blogs", PostLive.Index, :index
      live "/blogs/new", PostLive.Form, :new
      live "/blogs/:id/edit", PostLive.Form, :edit
      live "/blogs/:id", PostLive.Show, :show

      live "/newsletters", PostLive.Index, :index
      live "/newsletters/new", PostLive.Form, :new
      live "/newsletters/:id/edit", PostLive.Form, :edit
      live "/newsletters/:id", PostLive.Show, :show

      live "/press-releases", PostLive.Index, :index
      live "/press-releases/new", PostLive.Form, :new
      live "/press-releases/:id/edit", PostLive.Form, :edit
      live "/press-releases/:id", PostLive.Show, :show

      live "/media-invitations", PostLive.Index, :index
      live "/media-invitations/new", PostLive.Form, :new
      live "/media-invitations/:id/edit", PostLive.Form, :edit
      live "/media-invitations/:id", PostLive.Show, :show

      live "/events", EventLive.Index, :index
      live "/volunteers", VolunteerLive.Index, :index
      live "/emails", EmailLive.Index, :index
      live "/emails/new", EmailLive.Index, :new
      live "/emails/:id/analytics", EmailLive.Analytics, :show
      live "/emails/:id", EmailLive.Index, :show
      live "/sms", SmsLive.Index, :index
      live "/sms/new", SmsLive.Index, :new
      live "/sms/:id/analytics", SmsLive.Analytics, :show
      live "/sms/:id", SmsLive.Index, :show
      live "/media/photos", MediaLive.Index, :index
      live "/media/videos", MediaLive.Index, :index
      live "/media", MediaLive.Index, :index
      live "/pages", SectionLive, :pages
      live "/pages/home", HomePageLive, :index
      live "/pages/about", SectionLive, :page_about
      live "/pages/agenda", SectionLive, :page_agenda
      live "/pages/resources", SectionLive, :page_resources
      live "/pages/press", SectionLive, :page_press
      live "/pages/shop", SectionLive, :page_shop
      live "/settings", SectionLive, :settings
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
