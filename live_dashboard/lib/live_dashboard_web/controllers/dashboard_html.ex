defmodule LiveDashboardWeb.DashboardHTML do
  @moduledoc """
  Templates and components rendered by DashboardController.
  """

  use LiveDashboardWeb, :html

  embed_templates "dashboard_html/*"
end

