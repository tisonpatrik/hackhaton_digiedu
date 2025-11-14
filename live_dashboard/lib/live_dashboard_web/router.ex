defmodule LiveDashboardWeb.Router do
  use LiveDashboardWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LiveDashboardWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :set_locale
  end

  defp set_locale(conn, _opts) do
    locale = Plug.Conn.get_session(conn, "locale") || "en"
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)
    conn
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiveDashboardWeb do
    pipe_through :browser

    get "/set-locale/:locale", LocaleController, :set

    live "/", MainLive

    live "/regions", RegionsLive

    live "/schools", SchoolsLive

    live "/regions/:region_id/schools", SchoolsRegionLive

    live "/regions/:region_id/schools/:school_id", SchoolDetailLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveDashboardWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Mix.env() == :dev do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dev/dashboard", metrics: LiveDashboardWeb.Telemetry
    end
  end

  # Enable Swoosh mailbox preview in development
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
