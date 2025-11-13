defmodule LiveDashboardWeb.SchoolsLive do
  use LiveDashboardWeb, :live_view

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

  # Mock school data for demonstration
  @schools [
    %{
      id: 1,
      name: "Gymnázium Jana Nerudy",
      region_id: "praha",
      region_name: "Praha",
      municipality: "Praha 1",
      type: "Gymnázium",
      students: 450
    },
    %{
      id: 2,
      name: "Základní škola U Školky",
      region_id: "praha",
      region_name: "Praha",
      municipality: "Praha 2",
      type: "Základní škola",
      students: 320
    },
    %{
      id: 16,
      name: "Střední škola Praha 3",
      region_id: "praha",
      region_name: "Praha",
      municipality: "Praha 3",
      type: "Střední škola",
      students: 400
    },
    %{
      id: 17,
      name: "Gymnázium Praha 4",
      region_id: "praha",
      region_name: "Praha",
      municipality: "Praha 4",
      type: "Gymnázium",
      students: 350
    },
    %{
      id: 18,
      name: "Základní škola Praha 5",
      region_id: "praha",
      region_name: "Praha",
      municipality: "Praha 5",
      type: "Základní škola",
      students: 280
    },
    %{
      id: 3,
      name: "Střední průmyslová škola",
      region_id: "stredocesky",
      region_name: "Středočeský",
      municipality: "Kolín",
      type: "Střední škola",
      students: 280
    },
    %{
      id: 4,
      name: "Gymnázium České Budějovice",
      region_id: "jihocesky",
      region_name: "Jihočeský",
      municipality: "České Budějovice",
      type: "Gymnázium",
      students: 380
    },
    %{
      id: 5,
      name: "Základní škola Plzeň",
      region_id: "plzensky",
      region_name: "Plzeňský",
      municipality: "Plzeň",
      type: "Základní škola",
      students: 290
    },
    %{
      id: 6,
      name: "Technická univerzita Liberec",
      region_id: "liberecky",
      region_name: "Liberecký",
      municipality: "Liberec",
      type: "Vysoká škola",
      students: 5200
    },
    %{
      id: 7,
      name: "Gymnázium Hradec Králové",
      region_id: "kralovehradecky",
      region_name: "Královéhradecký",
      municipality: "Hradec Králové",
      type: "Gymnázium",
      students: 410
    },
    %{
      id: 8,
      name: "Univerzita Pardubice",
      region_id: "pardubicky",
      region_name: "Pardubický",
      municipality: "Pardubice",
      type: "Vysoká škola",
      students: 8900
    },
    %{
      id: 9,
      name: "Střední škola Jihlava",
      region_id: "vysocina",
      region_name: "Vysočina",
      municipality: "Jihlava",
      type: "Střední škola",
      students: 350
    },
    %{
      id: 10,
      name: "Masarykova univerzita",
      region_id: "jihomoravsky",
      region_name: "Jihomoravský",
      municipality: "Brno",
      type: "Vysoká škola",
      students: 32000
    },
    %{
      id: 11,
      name: "Univerzita Palackého",
      region_id: "olomoucky",
      region_name: "Olomoucký",
      municipality: "Olomouc",
      type: "Vysoká škola",
      students: 21000
    },
    %{
      id: 12,
      name: "Univerzita Tomáše Bati",
      region_id: "zlinsky",
      region_name: "Zlínský",
      municipality: "Zlín",
      type: "Vysoká škola",
      students: 9200
    },
    %{
      id: 13,
      name: "Ostravská univerzita",
      region_id: "moravskoslezsky",
      region_name: "Moravskoslezský",
      municipality: "Ostrava",
      type: "Vysoká škola",
      students: 9800
    },
    %{
      id: 14,
      name: "Vysoká škola báňská",
      region_id: "moravskoslezsky",
      region_name: "Moravskoslezský",
      municipality: "Ostrava",
      type: "Vysoká škola",
      students: 15600
    },
    %{
      id: 15,
      name: "Základní škola Ostrava",
      region_id: "moravskoslezsky",
      region_name: "Moravskoslezský",
      municipality: "Ostrava",
      type: "Základní škola",
      students: 275
    }
  ]

  @impl true
  def mount(_params, session, socket) do
    # Set locale from session
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    socket =
      socket
      |> assign(:regions, @regions)
      |> assign(:schools, @schools)
      |> assign(:search_query, "")
      |> assign(:selected_region, "")
      |> assign(:selected_type, "")
      |> assign(:selected_municipality, "")
      |> assign(:filtered_schools, @schools)

    {:ok, socket}
  end

  @impl true
  def handle_event("set-locale", %{"locale" => locale}, socket) when locale in ["en", "cs"] do
    # Navigate to controller endpoint which updates session
    {:noreply, push_navigate(socket, to: ~p"/set-locale/#{locale}")}
  end

  @impl true
  def handle_event(
        "filter",
        %{"query" => query, "region" => region, "type" => type, "municipality" => municipality},
        socket
      ) do
    filtered_schools = filter_schools(@schools, query, region, type, municipality)

    socket =
      socket
      |> assign(:search_query, query)
      |> assign(:selected_region, region)
      |> assign(:selected_type, type)
      |> assign(:selected_municipality, municipality)
      |> assign(:filtered_schools, filtered_schools)

    {:noreply, socket}
  end

  defp filter_schools(schools, query, region, type, municipality) do
    query = String.downcase(String.trim(query))
    region = String.trim(region)
    type = String.trim(type)
    municipality = String.trim(municipality)

    Enum.filter(schools, fn school ->
      matches_query =
        query == "" or
          String.contains?(String.downcase(school.name), query) or
          String.contains?(String.downcase(school.region_name), query) or
          String.contains?(String.downcase(school.type), query) or
          String.contains?(String.downcase(school.municipality), query)

      matches_region = region == "" or school.region_id == region

      matches_type = type == "" or school.type == type

      matches_municipality = municipality == "" or school.municipality == municipality

      matches_query and matches_region and matches_type and matches_municipality
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash}>
      <div class="px-6 py-10 sm:px-10 lg:px-16 xl:px-20">
        <header class="mb-8">
          <h1 class="text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
            {gettext("School Management")}
          </h1>
          <p class="mt-4 text-base leading-7 text-base-content/70">
            {gettext(
              "Manage educational institutions across regions. Select a region to view and manage schools."
            )}
          </p>
        </header>
        
    <!-- Search and Filters -->
        <div class="mb-8">
          <div class="max-w-6xl mx-auto bg-base-100 p-6 rounded-3xl border border-base-300/70 shadow-sm">
            <.form for={%{}} phx-change="filter" phx-submit="filter" class="space-y-4">
              <div class="grid gap-4 md:grid-cols-4">
                <label class="input input-bordered input-lg flex items-center gap-2">
                  <.icon name="hero-magnifying-glass" class="w-6 h-6 text-base-content/60" />
                  <input
                    type="text"
                    name="query"
                    class="grow text-lg"
                    placeholder={gettext("Search by name, region, municipality...")}
                    value={@search_query}
                  />
                </label>
                <select name="region" class="select select-bordered select-lg">
                  <option value="">{gettext("All Regions")}</option>
                  <option
                    :for={region <- @regions}
                    value={region.id}
                    selected={@selected_region == region.id}
                  >
                    {region.name}
                  </option>
                </select>
                <select name="municipality" class="select select-bordered select-lg">
                  <option value="">{gettext("All Municipalities")}</option>
                  <option
                    :for={
                      mun <-
                        Enum.uniq_by(@schools, & &1.municipality)
                        |> Enum.map(& &1.municipality)
                        |> Enum.sort()
                    }
                    value={mun}
                    selected={@selected_municipality == mun}
                  >
                    {mun}
                  </option>
                </select>
                <select name="type" class="select select-bordered select-lg">
                  <option value="">{gettext("All Types")}</option>
                  <option value="Gymnázium" selected={@selected_type == "Gymnázium"}>
                    {gettext("Gymnázium")}
                  </option>
                  <option value="Základní škola" selected={@selected_type == "Základní škola"}>
                    {gettext("Základní škola")}
                  </option>
                  <option value="Střední škola" selected={@selected_type == "Střední škola"}>
                    {gettext("Střední škola")}
                  </option>
                  <option value="Vysoká škola" selected={@selected_type == "Vysoká škola"}>
                    {gettext("Vysoká škola")}
                  </option>
                </select>
              </div>
            </.form>
          </div>
        </div>
        
    <!-- Filtered Schools -->
        <div
          :if={
            @search_query != "" or @selected_region != "" or @selected_type != "" or
              @selected_municipality != ""
          }
          class="mb-8"
        >
          <h2 class="text-2xl font-bold text-base-content mb-4">
            {gettext("Filtered Schools")} ({length(@filtered_schools)})
          </h2>

          <div :if={@filtered_schools == []} class="text-center py-8">
            <div class="mx-auto max-w-md">
              <.icon name="hero-magnifying-glass" class="mx-auto h-12 w-12 text-base-content/30 mb-4" />
              <p class="text-base-content/60">
                {gettext("No schools found matching your search.")}
              </p>
            </div>
          </div>

          <div :if={@filtered_schools != []} class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            <div
              :for={school <- @filtered_schools}
              class="card bg-base-100 shadow-sm border border-base-300/70"
            >
              <div class="card-body p-6">
                <div class="flex items-start justify-between">
                  <div class="flex-1">
                    <h3 class="card-title text-lg">{school.name}</h3>
                    <p class="text-sm text-base-content/70 mt-1">
                      {school.region_name} • {school.municipality} • {school.type}
                    </p>
                  </div>
                  <div class="badge badge-primary badge-outline">
                    {school.students} {gettext("students")}
                  </div>
                </div>
                <div class="card-actions justify-end mt-4">
                  <button class="btn btn-primary btn-sm">
                    <.icon name="hero-eye" class="w-4 h-4 mr-2" />
                    {gettext("View Details")}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Regions Overview (shown when no filters) -->
        <div :if={
          @search_query == "" and @selected_region == "" and @selected_type == "" and
            @selected_municipality == ""
        }>
          <h2 class="text-2xl font-bold text-base-content mb-6">
            {gettext("Browse by Region")}
          </h2>

          <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            <div :for={region <- @regions} class="group">
              <div class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg hover:border-primary/20">
                <div class="flex items-center justify-between mb-4">
                  <h3 class="text-xl font-bold text-base-content">{region.name}</h3>
                  <span class="rounded-full bg-primary/10 px-3 py-1 text-sm font-semibold text-primary">
                    {region.code}
                  </span>
                </div>
                <p class="text-sm text-base-content/60 mb-4">
                  {gettext("Manage schools and educational institutions")}
                </p>
                <div class="flex gap-2">
                  <.link
                    navigate={"/regions/#{region.id}/municipalities"}
                    class="btn btn-primary btn-sm flex-1"
                  >
                    <.icon name="hero-building-office" class="w-4 h-4 mr-2" />
                    {gettext("View Municipalities")}
                  </.link>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-12 rounded-3xl border border-dashed border-base-300/70 bg-base-100/50 p-8 text-center">
          <div class="mx-auto max-w-md">
            <.icon name="hero-building-office-2" class="mx-auto h-12 w-12 text-base-content/30 mb-4" />
            <h3 class="text-lg font-semibold text-base-content mb-2">
              {gettext("School Management System")}
            </h3>
            <p class="text-base-content/60 mb-4">
              {gettext(
                "This feature will allow you to create school profiles, upload data files, and manage educational institutions across all regions."
              )}
            </p>
          </div>
        </div>
      </div>
    </Layouts.dashboard>
    """
  end
end
