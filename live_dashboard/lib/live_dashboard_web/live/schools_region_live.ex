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

          <div>
            <h1 class="text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
              {gettext("Schools in")} {if @region, do: @region.name, else: gettext("Unknown Region")}
            </h1>
          </div>
        </header>

    <!-- Schools Grid -->
        <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          <div :for={school <- @schools} class="group">
            <.link
              navigate={~p"/schools/#{school.id}"}
              class="block"
            >
              <div class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg hover:border-primary/20">
                <h3 class="text-xl font-bold text-base-content">{school.name}</h3>
              </div>
            </.link>
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
      </div>
    </Layouts.dashboard>
    """
  end
end
