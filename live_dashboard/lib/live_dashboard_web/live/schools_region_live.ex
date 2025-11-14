defmodule LiveDashboardWeb.SchoolsRegionLive do
  use LiveDashboardWeb, :live_view

  import Ecto.Query

  alias LiveDashboard.Repo
  alias LiveDashboard.Schemas.Region
  alias LiveDashboard.Schemas.School

  @impl true
  def mount(%{"region_id" => region_id}, session, socket) do
    # Set locale from session
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    region = Repo.get_by(Region, slug: region_id)

    schools =
      if region do
        Repo.all(
          from s in School,
            where:
              s.municipality_id in subquery(
                from m in LiveDashboard.Schemas.Municipality,
                  where: m.region_id == ^region.id,
                  select: m.id
              ),
            preload: [:municipality]
        )
      else
        []
      end

    socket =
      socket
      |> assign(:region, region)
      |> assign(:schools, schools)

    {:ok, socket}
  end

  @impl true
  def handle_event("set-locale", %{"locale" => locale}, socket) when locale in ["en", "cs"] do
    # Navigate to controller endpoint which updates session
    {:noreply, push_navigate(socket, to: ~p"/set-locale/#{locale}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash}>
      <div class="px-6 py-10 sm:px-10 lg:px-16 xl:px-20">
        <!-- Header with breadcrumb -->
        <header class="mb-8">
          <nav class="flex mb-4" aria-label="Breadcrumb">
            <ol class="inline-flex items-center space-x-1 md:space-x-3">
              <li class="inline-flex items-center">
                <.link
                  navigate={~p"/schools"}
                  class="inline-flex items-center text-sm font-medium text-base-content/60 hover:text-base-content"
                >
                  <.icon name="hero-building-library" class="w-4 h-4 mr-2" />
                  {gettext("Schools")}
                </.link>
              </li>
              <li>
                <div class="flex items-center">
                  <.icon name="hero-chevron-right" class="w-4 h-4 text-base-content/40 mx-1" />
                  <span class="text-sm font-medium text-base-content">
                    {if @region, do: @region.name, else: gettext("Unknown Region")}
                  </span>
                </div>
              </li>
            </ol>
          </nav>

          <div class="flex items-center justify-between">
            <div>
              <h1 class="text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
                {gettext("Schools in")} {if @region, do: @region.name, else: gettext("Unknown Region")}
              </h1>
              <p class="mt-4 text-base leading-7 text-base-content/70">
                {gettext("Manage educational institutions in the")} {if @region,
                  do: @region.name,
                  else: gettext("selected")} {gettext("region")}
              </p>
            </div>
            <div :if={@region} class="flex items-center gap-3">
              <span class="badge badge-primary badge-lg">
                {@region.code}
              </span>
              <span class="text-sm text-base-content/60">
                {length(@schools)} {gettext("schools")}
              </span>
            </div>
          </div>
        </header>
        
    <!-- Schools Grid -->
        <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          <div
            :for={school <- @schools}
            class="card bg-base-100 shadow-sm border border-base-300/70 hover:shadow-lg transition-shadow"
          >
            <div class="card-body p-6">
              <div class="flex items-start justify-between mb-4">
                <div class="flex-1">
                  <h3 class="card-title text-lg text-base-content mb-1">{school.name}</h3>
                  <p class="text-sm text-base-content/70">
                    {school.type} • {(school.municipality && school.municipality.name) ||
                      "Unknown Municipality"}
                  </p>
                </div>
                <div class="badge badge-primary badge-outline">
                  {school.students || 0} {gettext("students")}
                </div>
              </div>

              <div class="flex items-center justify-between">
                <div class="text-sm text-base-content/60">
                  <.icon name="hero-map-pin" class="w-4 h-4 inline mr-1" />
                  {if @region, do: @region.name, else: gettext("Unknown Region")}
                </div>
                <.link
                  navigate={~p"/regions/#{@region.id}/schools/#{school.id}"}
                  class="btn btn-primary btn-sm"
                >
                  <.icon name="hero-eye" class="w-4 h-4 mr-2" />
                  {gettext("View Details")}
                </.link>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Empty State -->
        <div :if={@schools == []} class="text-center py-16">
          <div class="mx-auto max-w-md">
            <.icon name="hero-building-office" class="mx-auto h-16 w-16 text-base-content/30 mb-6" />
            <h3 class="text-xl font-semibold text-base-content mb-2">
              {gettext("No Schools Found")}
            </h3>
            <p class="text-base-content/60 mb-6">
              {gettext("There are currently no schools registered in the")} {if @region,
                do: @region.name,
                else: gettext("selected")} {gettext("region.")}
            </p>
            <button class="btn btn-primary">
              <.icon name="hero-plus" class="w-5 h-5 mr-2" />
              {gettext("Add First School")}
            </button>
          </div>
        </div>
        
    <!-- Back to Schools Overview -->
        <div class="mt-12 text-center">
          <.link navigate={~p"/schools"} class="btn btn-outline">
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" />
            {gettext("Back to All Schools")}
          </.link>
        </div>
      </div>
    </Layouts.dashboard>
    """
  end
end
