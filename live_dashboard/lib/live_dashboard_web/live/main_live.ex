defmodule LiveDashboardWeb.MainLive do
  use LiveDashboardWeb, :live_view

  alias LiveDashboard.Schemas.Region
  alias LiveDashboard.Repo
  alias LiveDashboard.Metrics
  alias LiveDashboardWeb.RegionHelpers
  import Ecto.Query

  @impl true
  def mount(_params, session, socket) do
    # Set locale from session
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    # Fetch regions from database
    regions = list_regions()

    # Initialize with first region selected by default
    selected_region_ids =
      case regions do
        [first_region | _] -> [first_region.id]
        _ -> []
      end

    # Get real metrics from database
    metrics = %{
      active_learners: Metrics.get_active_learners_count(),
      completion_rate: Metrics.get_completion_rate(),
      avg_session_length: Metrics.get_avg_session_length(),
      engagement_score: Metrics.get_engagement_score()
    }

    # Get recent activity
    recent_activity = Metrics.get_recent_activity()

    # Generate chart data for selected regions
    chart_data = get_engagement_chart_data(selected_region_ids, regions)

    socket =
      socket
      |> assign(:regions, regions)
      |> assign(:selected_region_ids, selected_region_ids)
      |> assign(:metrics, metrics)
      |> assign(:recent_activity, recent_activity)
      |> assign(:engagement_chart_data, chart_data)
      |> assign(:region_dropdown_open, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("set-locale", %{"locale" => locale}, socket) when locale in ["en", "cs"] do
    # Navigate to controller endpoint which updates session
    {:noreply, push_navigate(socket, to: ~p"/set-locale/#{locale}")}
  end

  def handle_event("toggle_region", %{"region_id" => region_id_str}, socket) do
    # Convert string ID to integer
    region_id =
      case Integer.parse(region_id_str) do
        {int, _} -> int
        :error -> nil
      end

    if region_id do
      # Toggle the region in the selected list
      selected_ids =
        if region_id in socket.assigns.selected_region_ids do
          # Remove if already selected
          List.delete(socket.assigns.selected_region_ids, region_id)
        else
          # Add if not selected
          [region_id | socket.assigns.selected_region_ids]
        end

      # Ensure at least one region is selected
      selected_ids = if Enum.empty?(selected_ids), do: [List.first(socket.assigns.regions).id], else: selected_ids

      # Generate chart data for selected regions
      chart_data = get_engagement_chart_data(selected_ids, socket.assigns.regions)

      socket =
        socket
        |> assign(:selected_region_ids, selected_ids)
        |> assign(:engagement_chart_data, chart_data)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("select_all_regions", _params, socket) do
    # Select all regions
    selected_ids = Enum.map(socket.assigns.regions, & &1.id)
    chart_data = get_engagement_chart_data(selected_ids, socket.assigns.regions)

    socket =
      socket
      |> assign(:selected_region_ids, selected_ids)
      |> assign(:engagement_chart_data, chart_data)

    {:noreply, socket}
  end

  def handle_event("toggle_dropdown", _params, socket) do
    new_state = !socket.assigns.region_dropdown_open
    {:noreply, assign(socket, :region_dropdown_open, new_state)}
  end

  def handle_event("deselect_all_regions", _params, socket) do
    # Deselect all, but keep at least one
    first_region_id = List.first(socket.assigns.regions).id
    chart_data = get_engagement_chart_data([first_region_id], socket.assigns.regions)

    socket =
      socket
      |> assign(:selected_region_ids, [first_region_id])
      |> assign(:engagement_chart_data, chart_data)

    {:noreply, socket}
  end

  defp list_regions do
    try do
      Repo.all(from r in Region, order_by: [asc: r.name])
      |> Enum.map(fn region ->
        %{
          id: region.id,
          name: region.name,
          slug: RegionHelpers.region_slug(region),
          code: region.code || ""
        }
      end)
    rescue
      _ -> []
    end
  end

  # Generate engagement chart data comparing selected regions
  defp get_engagement_chart_data(region_ids, all_regions) do
    # Filter regions to only selected ones
    selected_regions =
      all_regions
      |> Enum.filter(fn r -> r.id in region_ids end)

    # Generate labels (last 7 days)
    labels = generate_date_labels()

    # Generate datasets for each selected region
    datasets =
      selected_regions
      |> Enum.with_index()
      |> Enum.map(fn {region, index} ->
        # Generate unique color for each region
        colors = get_region_colors()
        color = Enum.at(colors, rem(index, length(colors)))

        %{
          label: region.name,
          data: generate_engagement_data(region.id),
          borderColor: color.border,
          backgroundColor: color.background,
          tension: 0.4,
          fill: false
        }
      end)

    %{
      labels: labels,
      datasets: datasets
    }
  end

  defp generate_date_labels do
    today = Date.utc_today()

    # Generate labels for last 7 days (6 days ago to today)
    Enum.map(0..6, fn days_ago ->
      date = Date.add(today, -days_ago)
      format_date(date)
    end)
    |> Enum.reverse()
  end

  defp format_date(date) do
    # Format as "Mon 14" or similar
    day_name = Calendar.strftime(date, "%a")
    day_num = date.day
    "#{day_name} #{day_num}"
  end

  defp generate_engagement_data(region_id) do
    # Generate mock engagement data based on region ID for consistency
    # In a real app, this would query actual engagement metrics
    # Use region_id as seed for consistent data
    :rand.seed(:exs1024, {region_id, region_id * 2, region_id * 3})
    base_value = rem(region_id, 100) + 50
    Enum.map(0..6, fn i ->
      # Add some variation but keep it consistent for the same region
      variation = :rand.uniform(30) - 15
      base_value + variation + (i * 2)
    end)
  end

  defp get_region_colors do
    [
      %{border: "rgb(59, 130, 246)", background: "rgba(59, 130, 246, 0.1)"},
      %{border: "rgb(16, 185, 129)", background: "rgba(16, 185, 129, 0.1)"},
      %{border: "rgb(245, 158, 11)", background: "rgba(245, 158, 11, 0.1)"},
      %{border: "rgb(239, 68, 68)", background: "rgba(239, 68, 68, 0.1)"},
      %{border: "rgb(139, 92, 246)", background: "rgba(139, 92, 246, 0.1)"},
      %{border: "rgb(236, 72, 153)", background: "rgba(236, 72, 153, 0.1)"},
      %{border: "rgb(14, 165, 233)", background: "rgba(14, 165, 233, 0.1)"},
      %{border: "rgb(34, 197, 94)", background: "rgba(34, 197, 94, 0.1)"},
      %{border: "rgb(251, 146, 60)", background: "rgba(251, 146, 60, 0.1)"},
      %{border: "rgb(168, 85, 247)", background: "rgba(168, 85, 247, 0.1)"}
    ]
  end


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
              <p class="mt-6 text-3xl font-bold tracking-tight text-base-content">1,284</p>
              <p class="mt-2 flex items-center gap-2 text-sm font-medium text-success">
                <.icon name="hero-arrow-trending-up" class="h-4 w-4" />
                {gettext("12.4% vs last 7 days")}
              </p>
              <p class="mt-3 text-xs text-base-content/60">
                {gettext("Upcoming: replace with real-time enrollment metrics.")}
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
              <p class="mt-6 text-3xl font-bold tracking-tight text-base-content">86%</p>
              <p class="mt-2 flex items-center gap-2 text-sm font-medium text-warning">
                <.icon name="hero-adjustments-horizontal" class="h-4 w-4" />
                {gettext("Stabilizing week over week")}
              </p>
              <p class="mt-3 text-xs text-base-content/60">
                {gettext("Hook into course analytics to surface live completion data.")}
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
              <p class="mt-6 text-3xl font-bold tracking-tight text-base-content">42m</p>
              <p class="mt-2 flex items-center gap-2 text-sm font-medium text-success">
                <.icon name="hero-sparkles" class="h-4 w-4" />
                {gettext("+6 minutes since launch")}
              </p>
              <p class="mt-3 text-xs text-base-content/60">
                {gettext("Pull telemetry data to track session depth across devices.")}
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
              <p class="mt-6 text-3xl font-bold tracking-tight text-base-content">8.7</p>
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
              <div class="mb-6">
                <h2 class="text-xl font-bold text-base-content">
                  {gettext("Region Comparison")}
                </h2>
                <p class="text-sm text-base-content/60 mt-1">
                  {gettext("Last 7 days engagement comparison")}
                </p>
              </div>

              <!-- Region Selection Dropdown -->
              <div class="mb-6">
                <div class="relative">
                  <button
                    type="button"
                    phx-click="toggle_dropdown"
                    class="w-full flex items-center justify-between px-4 py-3 rounded-lg border border-base-300/70 bg-base-100 hover:bg-base-200 transition-colors"
                  >
                    <div class="flex items-center gap-2">
                      <span class="font-medium text-base-content">{gettext("Compare Regions")}</span>
                      <span class="text-xs text-base-content/60">
                        {if length(@selected_region_ids) == length(@regions) do
                          gettext("All selected")
                        else
                          "#{length(@selected_region_ids)} #{gettext("selected")}"
                        end}
                      </span>
                    </div>
                    <svg
                      class={"w-5 h-5 text-base-content/60 transition-transform duration-200 #{if @region_dropdown_open, do: "rotate-180", else: ""}"}
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  </button>

                  <div
                    class={"absolute z-10 w-full mt-2 rounded-lg border border-base-300/70 bg-base-100 shadow-lg overflow-hidden transition-all duration-300 #{if @region_dropdown_open, do: "opacity-100 max-h-96", else: "opacity-0 max-h-0 pointer-events-none"}"}
                  >
                    <div class="p-3 border-b border-base-300/70 flex items-center justify-between bg-base-200/30">
                      <span class="text-sm font-semibold text-base-content">{gettext("Select Regions")}</span>
                      <div class="flex gap-2">
                        <button
                          type="button"
                          phx-click="select_all_regions"
                          class="btn btn-xs btn-ghost"
                        >
                          {gettext("All")}
                        </button>
                        <button
                          type="button"
                          phx-click="deselect_all_regions"
                          class="btn btn-xs btn-ghost"
                        >
                          {gettext("Clear")}
                        </button>
                      </div>
                    </div>
                    <div class="max-h-64 overflow-y-auto p-3 space-y-2">
                      <label
                        :for={region <- @regions}
                        class="flex items-center gap-3 p-2 rounded-lg hover:bg-base-200 cursor-pointer transition-colors"
                      >
                        <input
                          type="checkbox"
                          checked={region.id in @selected_region_ids}
                          phx-click="toggle_region"
                          phx-value-region_id={region.id}
                          class="checkbox checkbox-primary checkbox-sm"
                        />
                        <div class="flex-1">
                          <span class="font-medium text-base-content">{region.name}</span>
                          <span :if={region.code != ""} class="text-xs text-base-content/60 ml-2">
                            ({region.code})
                          </span>
                        </div>
                      </label>
                    </div>
                  </div>
                </div>
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
                <div class="flex items-start gap-4 p-4 rounded-xl bg-base-200/50 hover:bg-base-200 transition">
                  <div class="rounded-full bg-primary/10 p-2">
                    <.icon name="hero-user-plus" class="h-4 w-4 text-primary" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-semibold text-base-content">
                      {gettext("New learner enrolled")}
                    </p>
                    <p class="text-xs text-base-content/60 mt-1">
                      {gettext("Sarah M. joined \"Advanced Data Science\" course")}
                    </p>
                    <p class="text-xs text-base-content/50 mt-1">{gettext("2 minutes ago")}</p>
                  </div>
                </div>
                <div class="flex items-start gap-4 p-4 rounded-xl bg-base-200/50 hover:bg-base-200 transition">
                  <div class="rounded-full bg-success/10 p-2">
                    <.icon name="hero-check-circle" class="h-4 w-4 text-success" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-semibold text-base-content">
                      {gettext("Course completed")}
                    </p>
                    <p class="text-xs text-base-content/60 mt-1">
                      {gettext("John D. finished \"Introduction to Machine Learning\"")}
                    </p>
                    <p class="text-xs text-base-content/50 mt-1">{gettext("15 minutes ago")}</p>
                  </div>
                </div>
                <div class="flex items-start gap-4 p-4 rounded-xl bg-base-200/50 hover:bg-base-200 transition">
                  <div class="rounded-full bg-info/10 p-2">
                    <.icon name="hero-academic-cap" class="h-4 w-4 text-info" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-semibold text-base-content">
                      {gettext("Assignment submitted")}
                    </p>
                    <p class="text-xs text-base-content/60 mt-1">
                      {gettext("Emma L. submitted \"Week 3 Project\"")}
                    </p>
                    <p class="text-xs text-base-content/50 mt-1">{gettext("1 hour ago")}</p>
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
