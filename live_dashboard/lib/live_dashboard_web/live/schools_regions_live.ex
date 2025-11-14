defmodule LiveDashboardWeb.SchoolsRegionsLive do
  use LiveDashboardWeb, :live_view

  alias LiveDashboard.Repo
  alias LiveDashboard.Schemas.Region

  @impl true
  def mount(_params, session, socket) do
    # Set locale from session
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    regions =
      Repo.all(Region)
      |> Repo.preload(municipalities: [schools: []])
      |> Enum.map(&Map.put(&1, :schools_count, count_region_schools(&1)))

    # Calculate real statistics
    stats = %{
      total_regions: length(regions),
      regions_with_schools: length(Enum.filter(regions, &(&1.schools_count > 0))),
      total_municipalities: Enum.sum(Enum.map(regions, &length(&1.municipalities))),
      total_schools: Enum.sum(Enum.map(regions, & &1.schools_count))
    }

    socket =
      socket
      |> assign(:regions, regions)
      |> assign(:stats, stats)

    {:ok, socket}
  end

  defp count_region_schools(region) do
    region.municipalities
    |> Enum.flat_map(& &1.schools)
    |> length()
  end

  @impl true
  def handle_event("set-locale", %{"locale" => locale}, socket) when locale in ["en", "cs"] do
    {:noreply, push_navigate(socket, to: ~p"/set-locale/#{locale}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash}>
      <div class="px-6 py-10 sm:px-10 lg:px-16 xl:px-20">
        <!-- Breadcrumb -->
        <nav class="mb-6" aria-label="Breadcrumb">
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
                  {gettext("Browse by Region")}
                </span>
              </div>
            </li>
          </ol>
        </nav>
        
    <!-- Header -->
        <header class="mb-8">
          <h1 class="text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
            {gettext("Schools by Region")}
          </h1>
          <p class="mt-4 text-base leading-7 text-base-content/70">
            {gettext("Browse educational institutions organized by geographic regions")}
          </p>
        </header>
        
    <!-- Regions Grid -->
        <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          <div :for={region <- @regions} class="group">
            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg hover:border-primary/20">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-xl font-bold text-base-content">{region.name}</h3>
                <div class="flex items-center gap-2">
                  <span class="badge badge-primary badge-outline">
                    {region.schools_count} {gettext("schools")}
                  </span>
                  <span class="rounded-full bg-primary/10 px-3 py-1 text-sm font-semibold text-primary">
                    {region.code}
                  </span>
                </div>
              </div>
              <p class="text-sm text-base-content/60 mb-4">
                {gettext("Explore")} {length(region.municipalities)} {gettext("municipalities and")} {region.schools_count} {gettext(
                  "schools in this region"
                )}
              </p>
              <div class="flex gap-2">
                <.link
                  navigate={~p"/regions/#{region.slug}/schools"}
                  class="btn btn-primary btn-sm flex-1"
                >
                  <.icon name="hero-building-library" class="w-4 h-4 mr-2" />
                  {gettext("View Schools")}
                </.link>
                <.link
                  navigate={~p"/regions/#{region.slug}/municipalities"}
                  class="btn btn-outline btn-sm flex-1"
                >
                  <.icon name="hero-building-office" class="w-4 h-4 mr-2" />
                  {gettext("Municipalities")}
                </.link>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Stats Summary -->
        <div class="mt-12 rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
          <h2 class="text-xl font-bold text-base-content mb-6">
            {gettext("Regional Overview")}
          </h2>
          <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            <div class="text-center">
              <div class="text-2xl font-bold text-primary">{@stats.total_regions}</div>
              <div class="text-sm text-base-content/60">{gettext("Regions")}</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-secondary">{@stats.regions_with_schools}</div>
              <div class="text-sm text-base-content/60">{gettext("Regions with Schools")}</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-accent">{@stats.total_municipalities}</div>
              <div class="text-sm text-base-content/60">{gettext("Municipalities")}</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-info">{@stats.total_schools}</div>
              <div class="text-sm text-base-content/60">{gettext("Total Schools")}</div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.dashboard>
    """
  end
end
