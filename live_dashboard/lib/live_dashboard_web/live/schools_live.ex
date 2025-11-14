defmodule LiveDashboardWeb.SchoolsLive do
  use LiveDashboardWeb, :live_view

  alias LiveDashboard.Repo
  alias LiveDashboard.Schemas.Region
  alias LiveDashboard.Schemas.Municipality
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

    # Create empty changeset for the create form
    empty_school = %School{}
    school_form = School.changeset(empty_school, %{}) |> Phoenix.Component.to_form()

    socket =
      socket
      |> assign(:regions, regions)
      |> assign(:schools, schools)
      |> assign(:municipalities, municipalities)
      |> assign(:school_form, school_form)
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
  def handle_event("scroll_to_form", _params, socket) do
    {:noreply, push_event(socket, "scroll-to-form", %{})}
  end

  @impl true
  def handle_event("create_school", %{"school" => school_params}, socket) do
    municipality = Repo.get_by(Municipality, name: school_params["municipality_name"])

    if municipality do
      students_value =
        case school_params["students"] do
          "" ->
            nil

          nil ->
            nil

          str ->
            case Integer.parse(str) do
              {num, ""} when num > 0 -> num
              _ -> nil
            end
        end

      school_attrs = %{
        name: school_params["name"],
        type: school_params["type"],
        students: students_value,
        founder: school_params["founder"],
        municipality_id: municipality.id
      }

      case Repo.insert(School.changeset(%School{}, school_attrs)) do
        {:ok, _school} ->
          # Reload schools
          schools =
            Repo.all(School)
            |> Repo.preload(municipality: [:region])
            |> Enum.filter(&(&1.municipality && &1.municipality.region))

          municipalities =
            schools
            |> Enum.map(& &1.municipality)
            |> Enum.uniq_by(& &1.name)
            |> Enum.sort_by(& &1.name)

          filtered_schools =
            filter_schools(
              schools,
              socket.assigns.search_query,
              socket.assigns.selected_region,
              socket.assigns.selected_type,
              socket.assigns.selected_municipality
            )

          # Reset form
          empty_school = %School{}
          school_form = School.changeset(empty_school, %{}) |> Phoenix.Component.to_form()

          socket =
            socket
            |> assign(:schools, schools)
            |> assign(:municipalities, municipalities)
            |> assign(:school_form, school_form)
            |> assign(:filtered_schools, filtered_schools)
            |> put_flash(:info, gettext("School created successfully!"))

          {:noreply, socket}

        {:error, changeset} ->
          # Update form with errors
          school_form = Phoenix.Component.to_form(changeset)

          socket =
            socket
            |> assign(:school_form, school_form)
            |> put_flash(:error, gettext("Please fix the errors below"))

          {:noreply, socket}
      end
    else
      socket =
        socket
        |> put_flash(:error, gettext("Selected municipality not found"))

      {:noreply, socket}
    end
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
              <button
                id="add-school-btn"
                phx-click="scroll_to_form"
                phx-hook="ScrollToForm"
                class="btn btn-primary btn-sm"
                type="button"
              >
                <.icon name="hero-plus" class="w-4 h-4 mr-2" />
                {gettext("Add New School")}
              </button>
            </div>

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
                      {(school.municipality && school.municipality.region &&
                          school.municipality.region.name) || "Unknown Region"} • {(school.municipality &&
                                                                                      school.municipality.name) ||
                        "Unknown Municipality"} • {school.type}
                    </p>
                  </div>
                  <div class="badge badge-primary badge-outline">
                    {school.students} {gettext("students")}
                  </div>
                </div>
                <div class="card-actions justify-end mt-4">
                  <.link navigate={~p"/schools/#{school.id}"} class="btn btn-primary btn-sm">
                    <.icon name="hero-eye" class="w-4 h-4 mr-2" />
                    {gettext("View Details")}
                  </.link>
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
                    navigate={"/regions/#{region.slug}/municipalities"}
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
        
    <!-- Add School Form -->
        <div
          class="mt-12 rounded-3xl border border-base-300/70 bg-base-100 p-8"
          data-form="add-school"
        >
          <div class="mb-6">
            <h3 class="text-xl font-bold text-base-content mb-2">
              {gettext("Add New School")}
            </h3>
            <p class="text-base-content/60">
              {gettext("Create a new school profile with basic information.")}
            </p>
          </div>

          <.form for={@school_form} phx-submit="create_school" class="space-y-6">
            <div class="grid gap-6 md:grid-cols-2">
              <div>
                <label class="label">
                  <span class="label-text">{gettext("School Name")}</span>
                </label>
                <.input
                  field={@school_form[:name]}
                  class="input input-bordered w-full"
                  placeholder={gettext("Enter school name")}
                />
              </div>

              <div>
                <label class="label">
                  <span class="label-text">{gettext("School Type")}</span>
                </label>
                <.input
                  field={@school_form[:type]}
                  type="select"
                  class="select select-bordered w-full"
                  prompt={gettext("Select type")}
                  options={["Základní škola", "Střední škola", "Gymnázium", "Vysoká škola"]}
                />
              </div>

              <div>
                <label class="label">
                  <span class="label-text">{gettext("Region")}</span>
                </label>
                <select name="school[region_slug]" class="select select-bordered w-full" required>
                  <option value="">{gettext("Select region")}</option>
                  <option :for={region <- @regions} value={region.slug}>
                    {region.name}
                  </option>
                </select>
              </div>

              <div>
                <label class="label">
                  <span class="label-text">{gettext("Municipality")}</span>
                </label>
                <select
                  name="school[municipality_name]"
                  class="select select-bordered w-full"
                  required
                >
                  <option value="">{gettext("Select municipality")}</option>
                  <option
                    :for={municipality <- @municipalities}
                    value={municipality.name}
                  >
                    {municipality.name}
                  </option>
                </select>
              </div>

              <div>
                <label class="label">
                  <span class="label-text">{gettext("Number of Students")}</span>
                </label>
                <.input
                  field={@school_form[:students]}
                  type="number"
                  min="1"
                  class="input input-bordered w-full"
                  placeholder="0"
                />
              </div>

              <div>
                <label class="label">
                  <span class="label-text">{gettext("Founder (Optional)")}</span>
                </label>
                <.input
                  field={@school_form[:founder]}
                  class="input input-bordered w-full"
                  placeholder={gettext("Enter founder name")}
                />
              </div>
            </div>

            <div class="flex justify-end">
              <button type="submit" class="btn btn-primary">
                <.icon name="hero-plus" class="w-4 h-4 mr-2" />
                {gettext("Create School")}
              </button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.dashboard>
    """
  end
end
