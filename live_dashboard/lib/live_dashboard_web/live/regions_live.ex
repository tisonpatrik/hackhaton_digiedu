defmodule LiveDashboardWeb.RegionsLive do
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

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:selected_region, nil)
      |> assign(:regions, @regions)

    {:ok, socket}
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

  defp get_region_report(region_id) do
    %{
      active_learners: :rand.uniform(5000) + 1000,
      completion_rate: :rand.uniform(20) + 70,
      avg_session_length: :rand.uniform(30) + 30,
      engagement_score: Float.round(:rand.uniform() * 2 + 7.5, 1),
      courses_count: :rand.uniform(50) + 20,
      institutions_count: :rand.uniform(30) + 10
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash}>
      <div class="px-6 py-10 sm:px-10 lg:px-16 xl:px-20">
        <header class="mb-8">
          <h1 class="text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
            Regionální přehled
          </h1>
          <p class="mt-4 text-base leading-7 text-base-content/70">
            Klikněte na kraj v mapě pro zobrazení detailního reportu
          </p>
        </header>

        <div class="grid gap-6 lg:grid-cols-3">
          <div class="lg:col-span-2">
            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
              <div class="mb-6 flex items-center justify-between">
                <h2 class="text-xl font-bold text-base-content">Mapa České republiky</h2>
                <button
                  :if={@selected_region}
                  phx-click="deselect_region"
                  class="btn btn-ghost btn-sm"
                >
                  <.icon name="hero-x-mark" class="h-4 w-4" />
                  Zrušit výběr
                </button>
              </div>
              <div class="relative w-full">
                <svg
                  viewBox="0 0 600 500"
                  class="w-full h-auto"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <!-- Praha -->
                  <path
                    id="praha"
                    d="M 280 200 L 300 195 L 310 205 L 305 220 L 290 225 L 275 215 Z"
                    class={[
                      "region-path",
                      if(@selected_region && @selected_region.id == "praha", do: "selected", else: "")
                    ]}
                    phx-click="select_region"
                    phx-value-region_id="praha"
                  />
                  <!-- Středočeský -->
                  <path
                    id="stredocesky"
                    d="M 200 150 L 350 140 L 360 180 L 350 220 L 320 230 L 290 225 L 280 200 L 250 190 L 220 180 L 210 160 Z"
                    class={[
                      "region-path",
                      if(@selected_region && @selected_region.id == "stredocesky", do: "selected", else: "")
                    ]}
                    phx-click="select_region"
                    phx-value-region_id="stredocesky"
                  />
                  <!-- Jihočeský -->
                  <path
                    id="jihocesky"
                    d="M 200 250 L 320 240 L 330 280 L 320 320 L 280 330 L 250 310 L 220 290 L 210 270 Z"
                    class={[
                      "region-path",
                      if(@selected_region && @selected_region.id == "jihocesky", do: "selected", else: "")
                    ]}
                    phx-click="select_region"
                    phx-value-region_id="jihocesky"
                  />
                  <!-- Plzeňský -->
                  <path
                    id="plzensky"
                    d="M 100 200 L 200 190 L 210 270 L 200 310 L 150 320 L 120 300 L 110 250 Z"
                    class={[
                      "region-path",
                      if(@selected_region && @selected_region.id == "plzensky", do: "selected", else: "")
                    ]}
                    phx-click="select_region"
                    phx-value-region_id="plzensky"
                  />
                  <!-- Karlovarský -->
                  <path
                    id="karlovarsky"
                    d="M 50 150 L 100 145 L 110 200 L 100 240 L 70 250 L 40 230 L 35 180 Z"
                    class={[
                      "region-path",
                      if(@selected_region && @selected_region.id == "karlovarsky", do: "selected", else: "")
                    ]}
                    phx-click="select_region"
                    phx-value-region_id="karlovarsky"
                  />
                  <!-- Ústecký -->
                  <path
                    id="ustecky"
                    d="M 200 50 L 350 45 L 360 100 L 350 140 L 320 150 L 290 140 L 250 150 L 220 140 L 210 100 L 200 80 Z"
                    class={[
                      "region-path",
                      if(@selected_region && @selected_region.id == "ustecky", do: "selected", else: "")
                    ]}
                    phx-click="select_region"
                    phx-value-region_id="ustecky"
                  />
                  <!-- Liberecký -->
                  <path
                    id="liberecky"
                    d="M 350 100 L 450 95 L 460 140 L 450 180 L 420 190 L 390 180 L 360 170 L 350 140 Z"
                    class={[
                      "region-path",
                      if(@selected_region && @selected_region.id == "liberecky", do: "selected", else: "")
                    ]}
                    phx-click="select_region"
                    phx-value-region_id="liberecky"
                  />
                  <!-- Královéhradecký -->
                  <path
                    id="kralovehradecky"
                    d="M 450 140 L 550 135 L 560 180 L 550 220 L 520 230 L 490 220 L 460 210 L 450 180 Z"
                    class={[
                      "region-path",
                      if(@selected_region && @selected_region.id == "kralovehradecky", do: "selected", else: "")
                    ]}
                    phx-click="select_region"
                    phx-value-region_id="kralovehradecky"
                  />
                  <!-- Pardubický -->
                  <path
                    id="pardubicky"
                    d="M 450 220 L 550 215 L 560 260 L 550 300 L 520 310 L 490 300 L 460 290 L 450 260 Z"
                    class={[
                      "region-path",
                      if(@selected_region && @selected_region.id == "pardubicky", do: "selected", else: "")
                    ]}
                    phx-click="select_region"
                    phx-value-region_id="pardubicky"
                  />
                  <!-- Vysočina -->
                  <path
                    id="vysocina"
                    d="M 320 280 L 450 270 L 460 310 L 450 350 L 420 360 L 390 350 L 360 340 L 330 330 L 320 310 Z"
                    class={[
                      "region-path",
                      if(@selected_region && @selected_region.id == "vysocina", do: "selected", else: "")
                    ]}
                    phx-click="select_region"
                    phx-value-region_id="vysocina"
                  />
                  <!-- Jihomoravský -->
                  <path
                    id="jihomoravsky"
                    d="M 320 330 L 450 320 L 460 360 L 450 400 L 420 410 L 390 400 L 360 390 L 330 380 L 320 360 Z"
                    class={[
                      "region-path",
                      if(@selected_region && @selected_region.id == "jihomoravsky", do: "selected", else: "")
                    ]}
                    phx-click="select_region"
                    phx-value-region_id="jihomoravsky"
                  />
                  <!-- Olomoucký -->
                  <path
                    id="olomoucky"
                    d="M 450 300 L 550 295 L 560 340 L 550 380 L 520 390 L 490 380 L 460 370 L 450 340 Z"
                    class={[
                      "region-path",
                      if(@selected_region && @selected_region.id == "olomoucky", do: "selected", else: "")
                    ]}
                    phx-click="select_region"
                    phx-value-region_id="olomoucky"
                  />
                  <!-- Zlínský -->
                  <path
                    id="zlinsky"
                    d="M 450 380 L 550 375 L 560 420 L 550 460 L 520 470 L 490 460 L 460 450 L 450 420 Z"
                    class={[
                      "region-path",
                      if(@selected_region && @selected_region.id == "zlinsky", do: "selected", else: "")
                    ]}
                    phx-click="select_region"
                    phx-value-region_id="zlinsky"
                  />
                  <!-- Moravskoslezský -->
                  <path
                    id="moravskoslezsky"
                    d="M 450 420 L 550 415 L 560 460 L 550 500 L 520 510 L 490 500 L 460 490 L 450 460 Z"
                    class={[
                      "region-path",
                      if(@selected_region && @selected_region.id == "moravskoslezsky", do: "selected", else: "")
                    ]}
                    phx-click="select_region"
                    phx-value-region_id="moravskoslezsky"
                  />
                </svg>
              </div>
            </div>
          </div>

          <div class="lg:col-span-1">
            <div :if={@selected_region && @report_data} class="space-y-6">
              <div class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm">
                <div class="mb-4 flex items-center justify-between">
                  <h3 class="text-xl font-bold text-base-content">Kraj: {@selected_region.name}</h3>
                  <span class="rounded-full bg-primary/10 px-3 py-1 text-sm font-semibold text-primary">
                    {@selected_region.code}
                  </span>
                </div>
              </div>

              <div class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm">
                <h3 class="mb-4 text-lg font-bold text-base-content">Statistiky</h3>
                <div class="space-y-4">
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-base-content/70">Aktivní studenti</span>
                    <span class="text-lg font-bold text-base-content">
                      {Number.Delimit.number_to_delimited(@report_data.active_learners)}
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-base-content/70">Úspěšnost dokončení</span>
                    <span class="text-lg font-bold text-base-content">
                      {@report_data.completion_rate}%
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-base-content/70">Průměrná délka relace</span>
                    <span class="text-lg font-bold text-base-content">
                      {@report_data.avg_session_length} min
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-base-content/70">Engagement skóre</span>
                    <span class="text-lg font-bold text-base-content">
                      {@report_data.engagement_score}
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-base-content/70">Počet kurzů</span>
                    <span class="text-lg font-bold text-base-content">
                      {@report_data.courses_count}
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-base-content/70">Počet institucí</span>
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
                  Vyberte kraj v mapě pro zobrazení reportu
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

