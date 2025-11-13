defmodule LiveDashboardWeb.DashboardController do
  use LiveDashboardWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end

