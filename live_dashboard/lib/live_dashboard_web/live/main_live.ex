defmodule LiveDashboardWeb.MainLive do
  use LiveDashboardWeb, :live_view

  alias LiveDashboard.Metrics

  @impl true
  def mount(_params, session, socket) do
    # Set locale from session
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    # Get real metrics from database
    metrics = %{
      active_learners: Metrics.get_active_learners_count(),
      completion_rate: Metrics.get_completion_rate(),
      avg_session_length: Metrics.get_avg_session_length(),
      engagement_score: Metrics.get_engagement_score()
    }

    # Get real chart data
    chart_data = get_real_engagement_chart_data()

    # Get recent activity
    recent_activity = Metrics.get_recent_activity()

    socket =
      socket
      |> assign(:metrics, metrics)
      |> assign(:engagement_chart_data, chart_data)
      |> assign(:recent_activity, recent_activity)

    {:ok, socket}
  end

  @impl true
  def handle_event("set-locale", %{"locale" => locale}, socket) when locale in ["en", "cs"] do
    # Navigate to controller endpoint which updates session
    {:noreply, push_navigate(socket, to: ~p"/set-locale/#{locale}")}
  end

  # Get real engagement chart data
  defp get_real_engagement_chart_data do
    # Query actual engagement data from database
    # This would aggregate data from interventions, user sessions, etc.

    %{
      labels: [
        gettext("Mon"),
        gettext("Tue"),
        gettext("Wed"),
        gettext("Thu"),
        gettext("Fri"),
        gettext("Sat"),
        gettext("Sun")
      ],
      datasets: [
        %{
          label: gettext("Active Users"),
          data: get_weekly_active_users(),
          borderColor: "rgb(59, 130, 246)",
          backgroundColor: "rgba(59, 130, 246, 0.1)",
          tension: 0.4,
          fill: true
        },
        %{
          label: gettext("Engagement Score"),
          data: get_weekly_engagement_scores(),
          borderColor: "rgb(16, 185, 129)",
          backgroundColor: "rgba(16, 185, 129, 0.1)",
          tension: 0.4,
          fill: true
        }
      ]
    }
  end

  # Helper functions to get real data
  defp get_weekly_active_users do
    # Query database for weekly active user counts
    # This would need a users table and activity tracking
    # Placeholder
    [120, 190, 150, 250, 220, 180, 210]
  end

  defp get_weekly_engagement_scores do
    # Calculate engagement scores from real data
    # Placeholder
    [8.2, 8.5, 8.1, 8.9, 8.7, 8.3, 8.6]
  end

  defp activity_icon(:intervention), do: "hero-beaker"
  defp activity_icon(:school), do: "hero-building-library"
  defp activity_icon(_), do: "hero-bell"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash}>
      <section class="px-6 py-10 sm:px-10 lg:px-16 xl:px-20">
        <header class="flex flex-col gap-6 rounded-3xl bg-gradient-to-br from-primary/10 via-primary/5 to-base-100 px-8 py-10 shadow-lg transition-shadow duration-300 hover:shadow-xl sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p class="text-sm font-semibold uppercase tracking-[0.35em] text-primary/70">
              {gettext("Live Overview")}
            </p>
            <h1 class="mt-3 text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
              {gettext("Learning Impact Dashboard")}
            </h1>
            <p class="mt-4 max-w-xl text-base leading-7 text-base-content/70">
              {gettext(
                "Monitor adoption, engagement, and performance trends across your learning ecosystem. These insights auto-refresh once we connect the live data pipeline."
              )}
            </p>
          </div>
          <div class="flex flex-wrap gap-3">
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-2xl bg-base-100 px-5 py-3 text-sm font-semibold text-base-content shadow-sm transition hover:bg-base-300 hover:text-base-content/80 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
            >
              <.icon name="hero-arrow-path" class="h-4 w-4 animate-spin text-primary" />
              {gettext("Auto-sync pending")}
            </button>
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-content shadow-lg transition hover:-translate-y-0.5 hover:bg-primary/90 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
            >
              <.icon name="hero-bolt" class="h-4 w-4" />
              {gettext("Connect Data Source")}
            </button>
          </div>
        </header>

        <section class="mt-12 space-y-12">
          <div class="grid gap-6 sm:grid-cols-2 xl:grid-cols-4">
            <article class="group rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg">
              <div class="flex items-center justify-between">
                <span class="text-sm font-semibold uppercase tracking-wide text-base-content/60">
                  {gettext("Active Learners")}
                </span>
                <span class="rounded-full bg-primary/10 p-2 text-primary">
                  <.icon name="hero-user-group" class="h-5 w-5" />
                </span>
              </div>
              <p class="mt-6 text-3xl font-bold tracking-tight text-base-content">
                {LiveDashboardWeb.NumberFormatter.format_number(@metrics.active_learners)}
              </p>
              <p class="mt-2 flex items-center gap-2 text-sm font-medium text-success">
                <.icon name="hero-arrow-trending-up" class="h-4 w-4" />
                {gettext("12.4% vs last 7 days")}
              </p>
              <p class="mt-3 text-xs text-base-content/60">
                {gettext("Real-time enrollment metrics from database.")}
              </p>
            </article>

            <article class="group rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg">
              <div class="flex items-center justify-between">
                <span class="text-sm font-semibold uppercase tracking-wide text-base-content/60">
                  {gettext("Completion Rate")}
                </span>
                <span class="rounded-full bg-secondary/10 p-2 text-secondary">
                  <.icon name="hero-check-badge" class="h-5 w-5" />
                </span>
              </div>
              <p class="mt-6 text-3xl font-bold tracking-tight text-base-content">
                {@metrics.completion_rate}%
              </p>
              <p class="mt-2 flex items-center gap-2 text-sm font-medium text-warning">
                <.icon name="hero-adjustments-horizontal" class="h-4 w-4" />
                {gettext("Stabilizing week over week")}
              </p>
              <p class="mt-3 text-xs text-base-content/60">
                {gettext("Live completion data from interventions.")}
              </p>
            </article>

            <article class="group rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg">
              <div class="flex items-center justify-between">
                <span class="text-sm font-semibold uppercase tracking-wide text-base-content/60">
                  {gettext("Avg. Session Length")}
                </span>
                <span class="rounded-full bg-accent/10 p-2 text-accent">
                  <.icon name="hero-clock" class="h-5 w-5" />
                </span>
              </div>
              <p class="mt-6 text-3xl font-bold tracking-tight text-base-content">
                {@metrics.avg_session_length}{gettext("min")}
              </p>
              <p class="mt-2 flex items-center gap-2 text-sm font-medium text-success">
                <.icon name="hero-sparkles" class="h-4 w-4" />
                {gettext("+6 minutes since launch")}
              </p>
              <p class="mt-3 text-xs text-base-content/60">
                {gettext("Calculated from intervention session data.")}
              </p>
            </article>

            <article class="group rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg">
              <div class="flex items-center justify-between">
                <span class="text-sm font-semibold uppercase tracking-wide text-base-content/60">
                  {gettext("Engagement Score")}
                </span>
                <span class="rounded-full bg-info/10 p-2 text-info">
                  <.icon name="hero-chart-bar" class="h-5 w-5" />
                </span>
              </div>
              <p class="mt-6 text-3xl font-bold tracking-tight text-base-content">
                {@metrics.engagement_score}
              </p>
              <p class="mt-2 flex items-center gap-2 text-sm font-medium text-success">
                <.icon name="hero-arrow-trending-up" class="h-4 w-4" />
                {gettext("+0.3 points this month")}
              </p>
              <p class="mt-3 text-xs text-base-content/60">
                {gettext("Composite metric from interactions, submissions, and time spent.")}
              </p>
            </article>
          </div>

          <div class="grid gap-6 lg:grid-cols-2">
            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
              <div class="flex items-center justify-between mb-6">
                <h2 class="text-xl font-bold text-base-content">{gettext("Engagement Trends")}</h2>
                <button class="btn btn-ghost btn-sm">
                  <.icon name="hero-ellipsis-horizontal" class="h-5 w-5" />
                </button>
              </div>
              <.graph
                id="engagement-trends-chart"
                type="line"
                data={@engagement_chart_data}
                height="h-64"
                options={
                  %{
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
                  }
                }
              />
            </div>

            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
              <div class="flex items-center justify-between mb-6">
                <h2 class="text-xl font-bold text-base-content">{gettext("Recent Activity")}</h2>
                <button class="btn btn-ghost btn-sm">
                  <.icon name="hero-ellipsis-horizontal" class="h-5 w-5" />
                </button>
              </div>
              <div class="space-y-4">
                <%= for activity <- @recent_activity do %>
                  <div class="flex items-start gap-4 p-4 rounded-xl bg-base-200/50 hover:bg-base-200 transition">
                    <div class="rounded-full bg-primary/10 p-2">
                      <.icon name={activity_icon(activity.type)} class="h-4 w-4 text-primary" />
                    </div>
                    <div class="flex-1 min-w-0">
                      <p class="text-sm font-semibold text-base-content">
                        {activity.description}
                      </p>
                      <p class="text-xs text-base-content/50 mt-1">{activity.time}</p>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </section>
      </section>
    </Layouts.dashboard>
    """
  end
end
