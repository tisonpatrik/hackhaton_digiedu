defmodule LiveDashboardWeb.SchoolsAllLive do
  use LiveDashboardWeb, :live_view

  alias LiveDashboard.Repo
  alias LiveDashboard.Schemas.School

  @impl true
  def mount(_params, session, socket) do
    # Set locale from session
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    schools =
      Repo.all(School)
      |> Repo.preload(municipality: [:region])
      |> Enum.filter(&(&1.municipality && &1.municipality.region))

    socket =
      socket
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
        <header class="mb-8">
          <h1 class="text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
            {gettext("All Schools")}
          </h1>
          <p class="mt-4 text-base leading-7 text-base-content/70">
            {gettext("View all educational institutions across all regions.")}
          </p>
        </header>

        <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          <div
            :for={school <- @schools}
            class="card bg-base-100 shadow-sm border border-base-300/70 hover:shadow-lg transition-shadow"
          >
            <div class="card-body p-6">
              <div class="flex items-start justify-between mb-4">
                <div class="flex-1">
                  <h3 class="card-title text-lg text-base-content mb-1">{school.name}</h3>
                  <p class="text-sm text-base-content/70">{school.type}</p>
                  <p class="text-sm text-base-content/60">{school.municipality.region.name}</p>
                </div>
                <div class="badge badge-primary badge-outline">
                  {school.students} {gettext("students")}
                </div>
              </div>

              <div class="flex items-center justify-between">
                <div class="text-sm text-base-content/60">
                  <.icon name="hero-map-pin" class="w-4 h-4 inline mr-1" />
                  {school.municipality.region.name}
                </div>
                <.link navigate={~p"/schools/#{school.id}"} class="btn btn-primary btn-sm">
                  <.icon name="hero-eye" class="w-4 h-4 mr-2" />
                  {gettext("View Details")}
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.dashboard>
    """
  end
end
