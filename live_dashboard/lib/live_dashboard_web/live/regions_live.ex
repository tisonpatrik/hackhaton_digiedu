defmodule LiveDashboardWeb.RegionsLive do
  use LiveDashboardWeb, :live_view

  alias LiveDashboardWeb.RegionsData

  @regions [
    %{id: "praha", name: "Praha", code: "A"},
    %{id: "stredocesky", name: "Středočeský", code: "S"},
    %{id: "jihocesky", name: "Jihočeský", code: "C"},
    %{id: "plzensky", name: "Plzeňský", code: "P"},
    %{id: "karlovarsky", name: "Karlovarský", code: "K"},
    %{id: "ustecky", name: "Ústecký", code: "U"},
    %{id: "liberecky", name: "Liberecký", code: "L"},
    %{id: "kralovehradecky", name: "Královéhradecký", code: "H"},
    %{id: "pardubicky", name: "Pardubický", code: "E"},
    %{id: "vysocina", name: "Vysočina", code: "J"},
    %{id: "jihomoravsky", name: "Jihomoravský", code: "B"},
    %{id: "olomoucky", name: "Olomoucký", code: "M"},
    %{id: "zlinsky", name: "Zlínský", code: "Z"},
    %{id: "moravskoslezsky", name: "Moravskoslezský", code: "T"}
  ]

  @impl true
  def mount(_params, session, socket) do
    # Set locale from session
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    regions_geojson = RegionsData.get_regions_geojson()

    socket =
      socket
      |> assign(:selected_region, nil)
      |> assign(:regions, @regions)
      |> assign(:regions_geojson, regions_geojson)

    {:ok, socket}
  end

  @impl true
  def handle_event("set-locale", %{"locale" => locale}, socket) when locale in ["en", "cs"] do
    # Navigate to controller endpoint which updates session
    {:noreply, push_navigate(socket, to: ~p"/set-locale/#{locale}")}
  end

  @impl true
  def handle_event("select_region", %{"region_id" => region_id}, socket) do
    region = Enum.find(@regions, &(&1.id == region_id))
    report_data = get_region_report(region_id)

    socket =
      socket
      |> assign(:selected_region, region)
      |> assign(:report_data, report_data)

    {:noreply, socket}
  end

  def handle_event("deselect_region", _params, socket) do
    socket =
      socket
      |> assign(:selected_region, nil)
      |> assign(:report_data, nil)

    {:noreply, socket}
  end

  def handle_event("reset_map", _params, socket) do
    {:noreply, push_event(socket, "reset-map", %{})}
  end

  defp get_region_report(_region_id) do
    %{
      active_learners: :rand.uniform(5000) + 1000,
      completion_rate: :rand.uniform(20) + 70,
      avg_session_length: :rand.uniform(30) + 30,
      engagement_score: Float.round(:rand.uniform() * 2 + 7.5, 1),
      courses_count: :rand.uniform(50) + 20,
      institutions_count: :rand.uniform(30) + 10
    }
  end

  defp format_number(number) do
    number
    |> Integer.to_string()
    |> String.replace(~r/(\d)(?=(\d{3})+(?!\d))/, "\\1 ")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash}>
      <div class="px-6 py-10 sm:px-10 lg:px-16 xl:px-20">
        <header class="mb-8">
          <h1 class="text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
            {gettext("Regional Overview")}
          </h1>
          <p class="mt-4 text-base leading-7 text-base-content/70">
            {gettext("Click on a region in the map to view detailed report")}
          </p>
        </header>

        <div class="grid gap-6 lg:grid-cols-3">
          <div class="lg:col-span-2">
            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
              <div class="mb-6 flex items-center justify-between">
                <h2 class="text-xl font-bold text-base-content">{gettext("Map of Czech Republic")}</h2>
                <div class="flex items-center gap-2">
                  <button
                    phx-click="reset_map"
                    class="btn btn-ghost btn-sm"
                    title={gettext("Reset map view")}
                  >
                    <.icon name="hero-arrows-pointing-out" class="h-4 w-4" />
                    {gettext("Reset view")}
                  </button>
                  <button
                    :if={@selected_region}
                    phx-click="deselect_region"
                    class="btn btn-ghost btn-sm"
                  >
                    <.icon name="hero-x-mark" class="h-4 w-4" />
                    {gettext("Clear selection")}
                  </button>
                </div>
              </div>
              <div
                id="map"
                phx-hook="Map"
                phx-update="ignore"
                class="w-full h-[600px] rounded-xl"
              >
              </div>
            </div>
          </div>

          <div class="lg:col-span-1">
            <div :if={@selected_region && @report_data} class="space-y-6">
              <div class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm">
                <div class="mb-4 flex items-center justify-between">
                  <h3 class="text-xl font-bold text-base-content">{gettext("Region")}: {@selected_region.name}</h3>
                  <span class="rounded-full bg-primary/10 px-3 py-1 text-sm font-semibold text-primary">
                    {@selected_region.code}
                  </span>
                </div>
              </div>

              <div class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm">
                <h3 class="mb-4 text-lg font-bold text-base-content">{gettext("Statistics")}</h3>
                <div class="space-y-4">
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-base-content/70">{gettext("Active learners")}</span>
                    <span class="text-lg font-bold text-base-content">
                      {format_number(@report_data.active_learners)}
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-base-content/70">{gettext("Completion rate")}</span>
                    <span class="text-lg font-bold text-base-content">
                      {@report_data.completion_rate}%
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-base-content/70">{gettext("Average session length")}</span>
                    <span class="text-lg font-bold text-base-content">
                      {@report_data.avg_session_length} {gettext("min")}
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-base-content/70">{gettext("Engagement score")}</span>
                    <span class="text-lg font-bold text-base-content">
                      {@report_data.engagement_score}
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-base-content/70">{gettext("Number of courses")}</span>
                    <span class="text-lg font-bold text-base-content">
                      {@report_data.courses_count}
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-base-content/70">{gettext("Number of institutions")}</span>
                    <span class="text-lg font-bold text-base-content">
                      {@report_data.institutions_count}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div :if={!@selected_region} class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm">
              <div class="text-center py-12">
                <.icon name="hero-map" class="mx-auto h-12 w-12 text-base-content/30" />
                <p class="mt-4 text-base text-base-content/70">
                  {gettext("Select a region in the map to view report")}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.dashboard>
    """
  end
end
