defmodule LiveDashboardWeb.MainLive do
  use LiveDashboardWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Initialize with chart data from backend
    # Replace this with your actual backend data fetching logic
    chart_data = get_engagement_chart_data()

    socket =
      socket
      |> assign(:engagement_chart_data, chart_data)

    {:ok, socket}
  end

  # Replace this function with your actual backend data fetching
  # This is a placeholder that demonstrates the expected data format
  defp get_engagement_chart_data do
    # Example data structure - replace with real backend call
    # For example: YourBackend.get_engagement_data()
    %{
      labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      datasets: [
        %{
          label: "Active Users",
          data: [120, 190, 150, 250, 220, 180, 210],
          borderColor: "rgb(59, 130, 246)",
          backgroundColor: "rgba(59, 130, 246, 0.1)",
          tension: 0.4,
          fill: true
        },
        %{
          label: "Engagement Score",
          data: [8.2, 8.5, 8.1, 8.9, 8.7, 8.3, 8.6],
          borderColor: "rgb(16, 185, 129)",
          backgroundColor: "rgba(16, 185, 129, 0.1)",
          tension: 0.4,
          fill: true
        }
      ]
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash}>
      <section class="px-6 py-10 sm:px-10 lg:px-16 xl:px-20">
        <header class="flex flex-col gap-6 rounded-3xl bg-gradient-to-br from-primary/10 via-primary/5 to-base-100 px-8 py-10 shadow-lg transition-shadow duration-300 hover:shadow-xl sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p class="text-sm font-semibold uppercase tracking-[0.35em] text-primary/70">Live Overview</p>
            <h1 class="mt-3 text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
              Learning Impact Dashboard
            </h1>
            <p class="mt-4 max-w-xl text-base leading-7 text-base-content/70">
              Monitor adoption, engagement, and performance trends across your learning ecosystem.
              These insights auto-refresh once we connect the live data pipeline.
            </p>
          </div>
          <div class="flex flex-wrap gap-3">
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-2xl bg-base-100 px-5 py-3 text-sm font-semibold text-base-content shadow-sm transition hover:bg-base-300 hover:text-base-content/80 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
            >
              <.icon name="hero-arrow-path" class="h-4 w-4 animate-spin text-primary" />
              Auto-sync pending
            </button>
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-content shadow-lg transition hover:-translate-y-0.5 hover:bg-primary/90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
            >
              <.icon name="hero-bolt" class="h-4 w-4" />
              Connect Data Source
            </button>
          </div>
        </header>

        <section class="mt-12 space-y-12">
          <div class="grid gap-6 sm:grid-cols-2 xl:grid-cols-4">
            <article class="group rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg">
              <div class="flex items-center justify-between">
                <span class="text-sm font-semibold uppercase tracking-wide text-base-content/60">Active Learners</span>
                <span class="rounded-full bg-primary/10 p-2 text-primary">
                  <.icon name="hero-user-group" class="h-5 w-5" />
                </span>
              </div>
              <p class="mt-6 text-3xl font-bold tracking-tight text-base-content">1,284</p>
              <p class="mt-2 flex items-center gap-2 text-sm font-medium text-success">
                <.icon name="hero-arrow-trending-up" class="h-4 w-4" />
                12.4% vs last 7 days
              </p>
              <p class="mt-3 text-xs text-base-content/60">Upcoming: replace with real-time enrollment metrics.</p>
            </article>

            <article class="group rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg">
              <div class="flex items-center justify-between">
                <span class="text-sm font-semibold uppercase tracking-wide text-base-content/60">Completion Rate</span>
                <span class="rounded-full bg-secondary/10 p-2 text-secondary">
                  <.icon name="hero-check-badge" class="h-5 w-5" />
                </span>
              </div>
              <p class="mt-6 text-3xl font-bold tracking-tight text-base-content">86%</p>
              <p class="mt-2 flex items-center gap-2 text-sm font-medium text-warning">
                <.icon name="hero-adjustments-horizontal" class="h-4 w-4" />
                Stabilizing week over week
              </p>
              <p class="mt-3 text-xs text-base-content/60">Hook into course analytics to surface live completion data.</p>
            </article>

            <article class="group rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg">
              <div class="flex items-center justify-between">
                <span class="text-sm font-semibold uppercase tracking-wide text-base-content/60">Avg. Session Length</span>
                <span class="rounded-full bg-accent/10 p-2 text-accent">
                  <.icon name="hero-clock" class="h-5 w-5" />
                </span>
              </div>
              <p class="mt-6 text-3xl font-bold tracking-tight text-base-content">42m</p>
              <p class="mt-2 flex items-center gap-2 text-sm font-medium text-success">
                <.icon name="hero-sparkles" class="h-4 w-4" />
                +6 minutes since launch
              </p>
              <p class="mt-3 text-xs text-base-content/60">Pull telemetry data to track session depth across devices.</p>
            </article>

            <article class="group rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg">
              <div class="flex items-center justify-between">
                <span class="text-sm font-semibold uppercase tracking-wide text-base-content/60">Engagement Score</span>
                <span class="rounded-full bg-info/10 p-2 text-info">
                  <.icon name="hero-chart-bar" class="h-5 w-5" />
                </span>
              </div>
              <p class="mt-6 text-3xl font-bold tracking-tight text-base-content">8.7</p>
              <p class="mt-2 flex items-center gap-2 text-sm font-medium text-success">
                <.icon name="hero-arrow-trending-up" class="h-4 w-4" />
                +0.3 points this month
              </p>
              <p class="mt-3 text-xs text-base-content/60">Composite metric from interactions, submissions, and time spent.</p>
            </article>
          </div>

          <div class="grid gap-6 lg:grid-cols-2">
            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
              <div class="flex items-center justify-between mb-6">
                <h2 class="text-xl font-bold text-base-content">Engagement Trends</h2>
                <button class="btn btn-ghost btn-sm">
                  <.icon name="hero-ellipsis-horizontal" class="h-5 w-5" />
                </button>
              </div>
              <.graph
                id="engagement-trends-chart"
                type="line"
                data={@engagement_chart_data}
                height="h-64"
                options={%{
                  plugins: %{
                    legend: %{
                      display: true,
                      position: "top"
                    },
                    tooltip: %{
                      mode: "index",
                      intersect: false
                    }
                  },
                  scales: %{
                    y: %{
                      beginAtZero: true,
                      grid: %{
                        color: "rgba(0, 0, 0, 0.05)"
                      }
                    },
                    x: %{
                      grid: %{
                        display: false
                      }
                    }
                  }
                }}
              />
            </div>

            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
              <div class="flex items-center justify-between mb-6">
                <h2 class="text-xl font-bold text-base-content">Recent Activity</h2>
                <button class="btn btn-ghost btn-sm">
                  <.icon name="hero-ellipsis-horizontal" class="h-5 w-5" />
                </button>
              </div>
              <div class="space-y-4">
                <div class="flex items-start gap-4 p-4 rounded-xl bg-base-200/50 hover:bg-base-200 transition">
                  <div class="rounded-full bg-primary/10 p-2">
                    <.icon name="hero-user-plus" class="h-4 w-4 text-primary" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-semibold text-base-content">New learner enrolled</p>
                    <p class="text-xs text-base-content/60 mt-1">Sarah M. joined "Advanced Data Science" course</p>
                    <p class="text-xs text-base-content/50 mt-1">2 minutes ago</p>
                  </div>
                </div>
                <div class="flex items-start gap-4 p-4 rounded-xl bg-base-200/50 hover:bg-base-200 transition">
                  <div class="rounded-full bg-success/10 p-2">
                    <.icon name="hero-check-circle" class="h-4 w-4 text-success" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-semibold text-base-content">Course completed</p>
                    <p class="text-xs text-base-content/60 mt-1">John D. finished "Introduction to Machine Learning"</p>
                    <p class="text-xs text-base-content/50 mt-1">15 minutes ago</p>
                  </div>
                </div>
                <div class="flex items-start gap-4 p-4 rounded-xl bg-base-200/50 hover:bg-base-200 transition">
                  <div class="rounded-full bg-info/10 p-2">
                    <.icon name="hero-academic-cap" class="h-4 w-4 text-info" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-semibold text-base-content">Assignment submitted</p>
                    <p class="text-xs text-base-content/60 mt-1">Emma L. submitted "Week 3 Project"</p>
                    <p class="text-xs text-base-content/50 mt-1">1 hour ago</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </section>
    </Layouts.dashboard>
    """
  end
end
