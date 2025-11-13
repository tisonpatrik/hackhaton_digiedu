defmodule LiveDashboardWeb.DashboardLive do
  use LiveDashboardWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto max-w-7xl px-4 py-8">
        <h1 class="text-3xl font-bold text-base-content mb-8">Dashboard</h1>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Statistics</h2>
              <p>View your application statistics and metrics.</p>
              <div class="card-actions justify-end">
                <button class="btn btn-primary">View Stats</button>
              </div>
            </div>
          </div>

          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Recent Activity</h2>
              <p>Monitor recent user activity and events.</p>
              <div class="card-actions justify-end">
                <button class="btn btn-primary">View Activity</button>
              </div>
            </div>
          </div>

          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">System Health</h2>
              <p>Check system health and performance metrics.</p>
              <div class="card-actions justify-end">
                <button class="btn btn-primary">Check Health</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
