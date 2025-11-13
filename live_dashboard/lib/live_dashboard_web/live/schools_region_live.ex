defmodule LiveDashboardWeb.SchoolsRegionLive do
  use LiveDashboardWeb, :live_view

  @schools [
    %{
      id: 1,
      name: "Gymnázium Jana Nerudy",
      region_id: "praha",
      region_name: "Praha",
      type: "Gymnázium",
      students: 450
    },
    %{
      id: 2,
      name: "Základní škola U Školky",
      region_id: "praha",
      region_name: "Praha",
      type: "Základní škola",
      students: 320
    },
    %{
      id: 3,
      name: "Střední průmyslová škola",
      region_id: "stredocesky",
      region_name: "Středočeský",
      type: "Střední škola",
      students: 280
    },
    %{
      id: 4,
      name: "Gymnázium České Budějovice",
      region_id: "jihocesky",
      region_name: "Jihočeský",
      type: "Gymnázium",
      students: 380
    },
    %{
      id: 5,
      name: "Základní škola Plzeň",
      region_id: "plzensky",
      region_name: "Plzeňský",
      type: "Základní škola",
      students: 290
    },
    %{
      id: 6,
      name: "Technická univerzita Liberec",
      region_id: "liberecky",
      region_name: "Liberecký",
      type: "Vysoká škola",
      students: 5200
    },
    %{
      id: 7,
      name: "Gymnázium Hradec Králové",
      region_id: "kralovehradecky",
      region_name: "Královéhradecký",
      type: "Gymnázium",
      students: 410
    },
    %{
      id: 8,
      name: "Univerzita Pardubice",
      region_id: "pardubicky",
      region_name: "Pardubický",
      type: "Vysoká škola",
      students: 8900
    },
    %{
      id: 9,
      name: "Střední škola Jihlava",
      region_id: "vysocina",
      region_name: "Vysočina",
      type: "Střední škola",
      students: 350
    },
    %{
      id: 10,
      name: "Masarykova univerzita",
      region_id: "jihomoravsky",
      region_name: "Jihomoravský",
      type: "Vysoká škola",
      students: 32000
    },
    %{
      id: 11,
      name: "Univerzita Palackého",
      region_id: "olomoucky",
      region_name: "Olomoucký",
      type: "Vysoká škola",
      students: 21000
    },
    %{
      id: 12,
      name: "Univerzita Tomáše Bati",
      region_id: "zlinsky",
      region_name: "Zlínský",
      type: "Vysoká škola",
      students: 9200
    },
    %{
      id: 13,
      name: "Ostravská univerzita",
      region_id: "moravskoslezsky",
      region_name: "Moravskoslezský",
      type: "Vysoká škola",
      students: 9800
    },
    %{
      id: 14,
      name: "Vysoká škola báňská",
      region_id: "moravskoslezsky",
      region_name: "Moravskoslezský",
      type: "Vysoká škola",
      students: 15600
    },
    %{
      id: 15,
      name: "Základní škola Ostrava",
      region_id: "moravskoslezsky",
      region_name: "Moravskoslezský",
      type: "Základní škola",
      students: 275
    }
  ]

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
  def mount(%{"region_id" => region_id}, session, socket) do
    # Set locale from session
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    region = Enum.find(@regions, &(&1.id == region_id))
    region_schools = Enum.filter(@schools, &(&1.region_id == region_id))

    socket =
      socket
      |> assign(:region, region)
      |> assign(:schools, region_schools)

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
                  <span class="text-sm font-medium text-base-content">{@region.name}</span>
                </div>
              </li>
            </ol>
          </nav>

          <div class="flex items-center justify-between">
            <div>
              <h1 class="text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
                {gettext("Schools in")} {@region.name}
              </h1>
              <p class="mt-4 text-base leading-7 text-base-content/70">
                {gettext("Manage educational institutions in the")} {@region.name} {gettext("region")}
              </p>
            </div>
            <div class="flex items-center gap-3">
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
                  <p class="text-sm text-base-content/70">{school.type}</p>
                </div>
                <div class="badge badge-primary badge-outline">
                  {school.students} {gettext("students")}
                </div>
              </div>

              <div class="flex items-center justify-between">
                <div class="text-sm text-base-content/60">
                  <.icon name="hero-map-pin" class="w-4 h-4 inline mr-1" />
                  {@region.name}
                </div>
                <button class="btn btn-primary btn-sm">
                  <.icon name="hero-eye" class="w-4 h-4 mr-2" />
                  {gettext("View Details")}
                </button>
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
              {gettext("There are currently no schools registered in the")} {@region.name} {gettext(
                "region."
              )}
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
