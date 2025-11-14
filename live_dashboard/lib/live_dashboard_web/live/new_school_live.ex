defmodule LiveDashboardWeb.NewSchoolLive do
  use LiveDashboardWeb, :live_view

  alias LiveDashboard.Schemas.School
  alias LiveDashboard.Schemas.Municipality
  alias LiveDashboard.Repo
  import Ecto.Query

  @school_types [
    "Základní škola",
    "Střední škola",
    "Gymnázium",
    "Vysoká škola",
    "Mateřská škola",
    "Základní umělecká škola",
    "Jazyková škola",
    "Ostatní"
  ]

  @impl true
  def mount(_params, session, socket) do
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    # Fetch municipalities from database or use mock data
    municipalities = list_municipalities()

    changeset = School.changeset(%School{}, %{})

    socket =
      socket
      |> assign(:municipalities, municipalities)
      |> assign(:school_types, @school_types)
      |> assign(:form, to_form(changeset))

    {:ok, socket}
  end

  @impl true
  def handle_event("set-locale", %{"locale" => locale}, socket) when locale in ["en", "cs"] do
    {:noreply, push_navigate(socket, to: ~p"/set-locale/#{locale}")}
  end

  def handle_event("validate", %{"school" => school_params}, socket) do
    changeset =
      %School{}
      |> School.changeset(school_params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(:form, to_form(changeset))

    {:noreply, socket}
  end

  def handle_event("save", %{"school" => school_params}, socket) do
    case create_school(school_params) do
      {:ok, _school} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("School created successfully"))
         |> push_navigate(to: ~p"/schools")}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:form, to_form(changeset))
          |> put_flash(
            :error,
            gettext("Failed to create school. Please check the form for errors.")
          )

        {:noreply, socket}
    end
  end

  defp list_municipalities do
    try do
      Repo.all(from m in Municipality, order_by: [asc: m.name])
    rescue
      _ ->
        # Fallback to mock data if database is not set up
        get_mock_municipalities()
    end
  end

  defp get_mock_municipalities do
    [
      %{id: 1, name: "Praha 1"},
      %{id: 2, name: "Praha 2"},
      %{id: 3, name: "Praha 3"},
      %{id: 4, name: "Praha 4"},
      %{id: 5, name: "Praha 5"},
      %{id: 6, name: "Kolín"},
      %{id: 7, name: "České Budějovice"},
      %{id: 8, name: "Plzeň"},
      %{id: 9, name: "Liberec"},
      %{id: 10, name: "Hradec Králové"},
      %{id: 11, name: "Pardubice"},
      %{id: 12, name: "Jihlava"},
      %{id: 13, name: "Brno"},
      %{id: 14, name: "Olomouc"},
      %{id: 15, name: "Zlín"},
      %{id: 16, name: "Ostrava"}
    ]
  end

  defp create_school(attrs) do
    %School{}
    |> School.changeset(attrs)
    |> Repo.insert()
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
                <span class="text-sm font-medium text-base-content">{gettext("Add New School")}</span>
              </div>
            </li>
          </ol>
        </nav>
        
    <!-- Header -->
        <header class="mb-8">
          <h1 class="text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
            {gettext("Add New School")}
          </h1>
          <p class="mt-4 text-base leading-7 text-base-content/70">
            {gettext("Create a new school profile by filling in the information below")}
          </p>
        </header>
        
    <!-- Form -->
        <div class="max-w-3xl">
          <form phx-submit="save" phx-change="validate" class="space-y-6">
            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
              <h2 class="text-xl font-bold text-base-content mb-6">
                {gettext("School Information")}
              </h2>

              <div class="space-y-4">
                <.input
                  field={@form[:name]}
                  type="text"
                  label={gettext("School Name")}
                  placeholder={gettext("Enter school name")}
                  required
                />

                <.input
                  field={@form[:type]}
                  type="select"
                  label={gettext("School Type")}
                  prompt={gettext("Select school type")}
                  options={Enum.map(@school_types, fn type -> {type, type} end)}
                  required
                />

                <.input
                  field={@form[:municipality_id]}
                  type="select"
                  label={gettext("Municipality")}
                  prompt={gettext("Select municipality")}
                  options={Enum.map(@municipalities, fn m -> {m.name, m.id} end)}
                  required
                />

                <.input
                  field={@form[:students]}
                  type="number"
                  label={gettext("Number of Students")}
                  placeholder="0"
                  min="0"
                />

                <.input
                  field={@form[:founder]}
                  type="text"
                  label={gettext("Founder")}
                  placeholder={gettext("Enter founder name (optional)")}
                />
              </div>

              <div class="mt-6 flex justify-end gap-3">
                <.link
                  navigate={~p"/schools"}
                  class="btn btn-ghost"
                >
                  {gettext("Cancel")}
                </.link>
                <button type="submit" class="btn btn-primary">
                  <.icon name="hero-plus" class="w-5 h-5 mr-2" />
                  {gettext("Create School")}
                </button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </Layouts.dashboard>
    """
  end
end
