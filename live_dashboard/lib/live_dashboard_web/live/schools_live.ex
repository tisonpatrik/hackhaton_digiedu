defmodule LiveDashboardWeb.SchoolsLive do
  use LiveDashboardWeb, :live_view

  alias LiveDashboard.Repo
  alias LiveDashboard.Schemas.Region
  alias LiveDashboard.Schemas.School

  @impl true
  def mount(_params, session, socket) do
    # Set locale from session
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    regions = Repo.all(Region)

    schools =
      Repo.all(School)
      |> Repo.preload(municipality: [:region])
      |> Enum.filter(&(&1.municipality && &1.municipality.region))

    municipalities =
      schools
      |> Enum.map(& &1.municipality)
      |> Enum.uniq_by(& &1.name)
      |> Enum.sort_by(& &1.name)

    socket =
      socket
      |> assign(:regions, regions)
      |> assign(:schools, schools)
      |> assign(:municipalities, municipalities)
      |> assign(:search_query, "")
      |> assign(:selected_region, "")
      |> assign(:selected_type, "")
      |> assign(:selected_municipality, "")
      |> assign(:filtered_schools, schools)

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
    filtered_schools = filter_schools(socket.assigns.schools, query, region, type, municipality)

    socket =
      socket
      |> assign(:search_query, query)
      |> assign(:selected_region, region)
      |> assign(:selected_type, type)
      |> assign(:selected_municipality, municipality)
      |> assign(:filtered_schools, filtered_schools)

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    socket =
      socket
      |> assign(:search_query, "")
      |> assign(:selected_region, "")
      |> assign(:selected_type, "")
      |> assign(:selected_municipality, "")
      |> assign(:filtered_schools, socket.assigns.schools)

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_type", %{"type" => type}, socket) do
    filtered_schools =
      filter_schools(
        socket.assigns.schools,
        socket.assigns.search_query,
        socket.assigns.selected_region,
        type,
        socket.assigns.selected_municipality
      )

    socket =
      socket
      |> assign(:selected_type, type)
      |> assign(:filtered_schools, filtered_schools)

    {:noreply, socket}
  end

  defp filter_schools(schools, query, region, type, municipality) do
    query = String.downcase(String.trim(query))
    region = String.trim(region)
    type = String.trim(type)
    municipality = String.trim(municipality)

    Enum.filter(schools, fn school ->
      region_name =
        (school.municipality && school.municipality.region && school.municipality.region.name) ||
          ""

      municipality_name = (school.municipality && school.municipality.name) || ""

      region_slug =
        (school.municipality && school.municipality.region && school.municipality.region.slug) ||
          ""

      matches_query =
        query == "" or
          String.contains?(String.downcase(school.name), query) or
          String.contains?(String.downcase(region_name), query) or
          String.contains?(String.downcase(school.type), query) or
          String.contains?(String.downcase(municipality_name), query)

      matches_region = region == "" or region_slug == region

      matches_type = type == "" or school.type == type

      matches_municipality = municipality == "" or municipality_name == municipality

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
            {gettext("All Schools")}
          </h1>
        </header>

    <!-- Search and Filters -->
        <div class="mb-8">
          <div class="bg-base-100 p-6 rounded-3xl border border-base-300/70 shadow-sm">
            <!-- Header with Add Button -->
            <div class="flex items-center justify-between mb-6">
              <div>
                <h2 class="text-xl font-bold text-base-content">
                  {gettext("Search & Filter Schools")}
                </h2>
                <p class="text-sm text-base-content/60 mt-1">
                  {gettext("Find schools by name, region, type, or municipality")}
                </p>
              </div>
              <.link
                navigate={~p"/schools/new"}
                class="btn btn-primary btn-sm"
              >
                <.icon name="hero-plus" class="w-4 h-4 mr-2" />
                {gettext("Add New School")}
              </.link>
            </div>

    <!-- Quick Filters -->
            <div class="flex flex-wrap gap-2 mb-6">
              <button
                phx-click="clear_filters"
                class="btn btn-sm btn-ghost"
                disabled={
                  @search_query == "" and @selected_region == "" and @selected_type == "" and
                    @selected_municipality == ""
                }
              >
                <.icon name="hero-x-mark" class="w-4 h-4 mr-1" />
                {gettext("Clear All")}
              </button>
              <div class="divider divider-horizontal"></div>
              <span class="text-sm text-base-content/60 self-center mr-2">
                {gettext("Quick Filters:")}
              </span>
              <button
                phx-click="filter_type"
                phx-value-type="Základní škola"
                class="btn btn-sm btn-outline"
              >
                {gettext("Elementary")}
              </button>
              <button
                phx-click="filter_type"
                phx-value-type="Gymnázium"
                class="btn btn-sm btn-outline"
              >
                {gettext("Gymnasium")}
              </button>
              <button
                phx-click="filter_type"
                phx-value-type="Střední škola"
                class="btn btn-sm btn-outline"
              >
                {gettext("Secondary")}
              </button>
              <button
                phx-click="filter_type"
                phx-value-type="Vysoká škola"
                class="btn btn-sm btn-outline"
              >
                {gettext("University")}
              </button>
            </div>

            <.form for={%{}} phx-change="filter" phx-submit="filter" class="space-y-4">
              <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
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
                    value={region.slug}
                    selected={@selected_region == region.slug}
                  >
                    {region.name}
                  </option>
                </select>
                <select name="municipality" class="select select-bordered select-lg">
                  <option value="">{gettext("All Municipalities")}</option>
                  <option
                    :for={municipality <- @municipalities}
                    value={municipality.name}
                    selected={@selected_municipality == municipality.name}
                  >
                    {municipality.name}
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
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-2xl font-bold text-base-content">
              {gettext("Search Results")} ({length(@filtered_schools)})
            </h2>
            <.link navigate={~p"/schools"} class="btn btn-sm btn-ghost">
              <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" />
              {gettext("View All Schools")}
            </.link>
          </div>

          <div :if={@filtered_schools == []} class="text-center py-12">
            <div class="mx-auto max-w-md">
              <.icon name="hero-magnifying-glass" class="mx-auto h-16 w-16 text-base-content/30 mb-6" />
              <h3 class="text-lg font-semibold text-base-content mb-2">
                {gettext("No schools found")}
              </h3>
              <p class="text-base-content/60 mb-6">
                {gettext("Try adjusting your search criteria or browse all schools.")}
              </p>
              <.link navigate={~p"/schools"} class="btn btn-primary">
                <.icon name="hero-building-library" class="w-4 h-4 mr-2" />
                {gettext("View All Schools")}
              </.link>
            </div>
          </div>

          <div :if={@filtered_schools != []} class="grid gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            <div :for={school <- @filtered_schools} class="group">
              <.link
                navigate={~p"/schools/#{school.id}"}
                class="block"
              >
                <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg hover:border-primary/20">
                  <h3 class="text-2xl font-bold text-base-content">{school.name}</h3>
                </div>
              </.link>
            </div>
          </div>
        </div>

    <!-- Schools Overview (shown when no filters) -->
        <div :if={
          @search_query == "" and @selected_region == "" and @selected_type == "" and
            @selected_municipality == ""
        }>
          <div class="mb-8">
            <h2 class="text-2xl font-bold text-base-content mb-4">
              {gettext("All Schools")} ({length(@schools)})
            </h2>
          </div>

          <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            <div :for={school <- @schools} class="group">
              <.link
                navigate={~p"/schools/#{school.id}"}
                class="block"
              >
                <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg hover:border-primary/20">
                  <h3 class="text-2xl font-bold text-base-content">{school.name}</h3>
                </div>
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.dashboard>
    """
  end
end
