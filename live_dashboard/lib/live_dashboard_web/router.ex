defmodule LiveDashboardWeb.Router do
  use LiveDashboardWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LiveDashboardWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiveDashboardWeb do
    pipe_through :browser

    live "/", MainLive
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
