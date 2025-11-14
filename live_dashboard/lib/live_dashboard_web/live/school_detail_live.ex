defmodule LiveDashboardWeb.SchoolDetailLive do
  use LiveDashboardWeb, :live_view

  alias LiveDashboard.School
  alias LiveDashboard.Repo

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
  def mount(%{"region_id" => region_id, "school_id" => school_id}, session, socket) do
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    region = Enum.find(@regions, &(&1.id == region_id))
    
    # Try to get school from database, fallback to mock data if not found
    school = get_school(school_id) || get_mock_school(school_id, region_id)
    
    socket =
      socket
      |> assign(:region, region)
      |> assign(:school, school)
      |> assign(:editing, false)
      |> assign(:form, to_form(School.changeset(%School{}, %{})))

    {:ok, socket}
  end

  @impl true
  def handle_event("set-locale", %{"locale" => locale}, socket) when locale in ["en", "cs"] do
    {:noreply, push_navigate(socket, to: ~p"/set-locale/#{locale}")}
  end

  def handle_event("edit", _params, socket) do
    changeset = School.changeset(socket.assigns.school, %{
      name: socket.assigns.school.name,
      region_id: socket.assigns.school.region_id,
      type: socket.assigns.school.type,
      students: socket.assigns.school.students,
      address: socket.assigns.school.address || "",
      phone: socket.assigns.school.phone || "",
      email: socket.assigns.school.email || "",
      website: socket.assigns.school.website || "",
      description: socket.assigns.school.description || ""
    })

    socket =
      socket
      |> assign(:editing, true)
      |> assign(:form, to_form(changeset))

    {:noreply, socket}
  end

  def handle_event("cancel_edit", _params, socket) do
    socket =
      socket
      |> assign(:editing, false)
      |> assign(:form, to_form(School.changeset(%School{}, %{})))

    {:noreply, socket}
  end

  def handle_event("validate", %{"school" => school_params}, socket) do
    changeset =
      socket.assigns.school
      |> School.changeset(school_params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(:form, to_form(changeset))

    {:noreply, socket}
  end

  def handle_event("save", %{"school" => school_params}, socket) do
    case save_school(socket.assigns.school, school_params) do
      {:ok, school} ->
        socket =
          socket
          |> assign(:school, school)
          |> assign(:editing, false)
          |> assign(:form, to_form(School.changeset(%School{}, %{})))
          |> put_flash(:info, gettext("School updated successfully"))

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:form, to_form(changeset))
          |> put_flash(:error, gettext("Failed to update school"))

        {:noreply, socket}
    end
  end

  def handle_event("delete", _params, socket) do
    case delete_school(socket.assigns.school) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("School deleted successfully"))
         |> push_navigate(to: ~p"/regions/#{socket.assigns.region.id}/schools")}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Failed to delete school"))

        {:noreply, socket}
    end
  end

  defp get_school(school_id) do
    try do
      Repo.get(School, school_id)
    rescue
      _ -> nil
    end
  end

  defp get_mock_school(school_id, region_id) do
    # Mock data matching the structure from SchoolsRegionLive - all schools from all regions
    mock_schools = [
      %{id: 1, name: "Gymnázium Jana Nerudy", region_id: "praha", type: "Gymnázium", students: 450, address: "Hellichova 3, 118 00 Praha 1", phone: "+420 257 533 534", email: "info@gjn.cz", website: "https://www.gjn.cz", description: "Elite grammar school in Prague"},
      %{id: 2, name: "Základní škola U Školky", region_id: "praha", type: "Základní škola", students: 320, address: "U Školky 1, 150 00 Praha 5", phone: "+420 251 555 123", email: "info@uskolky.cz", website: "https://www.uskolky.cz", description: "Elementary school in Prague 5"},
      %{id: 3, name: "Střední průmyslová škola", region_id: "stredocesky", type: "Střední škola", students: 280, address: "Hlavní 123, 250 00 Mělník", phone: "+420 315 123 456", email: "info@sps-melnik.cz", website: "https://www.sps-melnik.cz", description: "Technical high school in Central Bohemia"},
      %{id: 4, name: "Gymnázium České Budějovice", region_id: "jihocesky", type: "Gymnázium", students: 380, address: "Jirsíkova 1, 370 01 České Budějovice", phone: "+420 387 123 456", email: "info@gymcb.cz", website: "https://www.gymcb.cz", description: "Grammar school in České Budějovice"},
      %{id: 5, name: "Základní škola Plzeň", region_id: "plzensky", type: "Základní škola", students: 290, address: "Náměstí Republiky 1, 301 00 Plzeň", phone: "+420 377 123 456", email: "info@zsplzen.cz", website: "https://www.zsplzen.cz", description: "Elementary school in Plzeň"},
      %{id: 6, name: "Technická univerzita Liberec", region_id: "liberecky", type: "Vysoká škola", students: 5200, address: "Studentská 2, 461 17 Liberec", phone: "+420 485 123 456", email: "info@tul.cz", website: "https://www.tul.cz", description: "Technical University of Liberec"},
      %{id: 7, name: "Gymnázium Hradec Králové", region_id: "kralovehradecky", type: "Gymnázium", students: 410, address: "Eliščino nábřeží 1, 500 03 Hradec Králové", phone: "+420 495 123 456", email: "info@gymhk.cz", website: "https://www.gymhk.cz", description: "Grammar school in Hradec Králové"},
      %{id: 8, name: "Univerzita Pardubice", region_id: "pardubicky", type: "Vysoká škola", students: 8900, address: "Studentská 95, 532 10 Pardubice", phone: "+420 466 123 456", email: "info@upce.cz", website: "https://www.upce.cz", description: "University of Pardubice"},
      %{id: 9, name: "Střední škola Jihlava", region_id: "vysocina", type: "Střední škola", students: 350, address: "Havlíčkova 1, 586 01 Jihlava", phone: "+420 567 123 456", email: "info@ssjihlava.cz", website: "https://www.ssjihlava.cz", description: "High school in Jihlava"},
      %{id: 10, name: "Masarykova univerzita", region_id: "jihomoravsky", type: "Vysoká škola", students: 32000, address: "Žerotínovo nám. 9, 601 77 Brno", phone: "+420 549 123 456", email: "info@muni.cz", website: "https://www.muni.cz", description: "Masaryk University in Brno"},
      %{id: 11, name: "Univerzita Palackého", region_id: "olomoucky", type: "Vysoká škola", students: 21000, address: "Křížkovského 8, 771 47 Olomouc", phone: "+420 585 123 456", email: "info@upol.cz", website: "https://www.upol.cz", description: "Palacký University in Olomouc"},
      %{id: 12, name: "Univerzita Tomáše Bati", region_id: "zlinsky", type: "Vysoká škola", students: 9200, address: "nám. T. G. Masaryka 5555, 760 01 Zlín", phone: "+420 576 123 456", email: "info@utb.cz", website: "https://www.utb.cz", description: "Tomas Bata University in Zlín"},
      %{id: 13, name: "Ostravská univerzita", region_id: "moravskoslezsky", type: "Vysoká škola", students: 9800, address: "Dvořákova 7, 701 03 Ostrava", phone: "+420 597 123 456", email: "info@osu.cz", website: "https://www.osu.cz", description: "University of Ostrava"},
      %{id: 14, name: "Vysoká škola báňská", region_id: "moravskoslezsky", type: "Vysoká škola", students: 15600, address: "17. listopadu 2172/15, 708 00 Ostrava", phone: "+420 597 123 789", email: "info@vsb.cz", website: "https://www.vsb.cz", description: "VSB - Technical University of Ostrava"},
      %{id: 15, name: "Základní škola Ostrava", region_id: "moravskoslezsky", type: "Základní škola", students: 275, address: "Hlavní 100, 700 30 Ostrava", phone: "+420 597 456 789", email: "info@zsostrava.cz", website: "https://www.zsostrava.cz", description: "Elementary school in Ostrava"},
    ]

    school_id_int = try do
      String.to_integer(school_id)
    rescue
      _ -> nil
    end

    if school_id_int do
      school = Enum.find(mock_schools, &(&1.id == school_id_int && &1.region_id == region_id))
      
      if school do
        # Convert to School struct-like map
        %{
          id: school.id,
          name: school.name,
          region_id: school.region_id,
          type: school.type,
          students: school.students,
          address: school.address || "",
          phone: school.phone || "",
          email: school.email || "",
          website: school.website || "",
          description: school.description || ""
        }
      else
        nil
      end
    else
      nil
    end
  end

  defp save_school(school, attrs) do
    # If school is a struct (from database), update it
    if Map.has_key?(school, :__struct__) && school.__struct__ == School do
      school
      |> School.changeset(attrs)
      |> Repo.update()
    else
      # For mock data, convert string keys to atom keys and handle type conversions
      attrs_atom = %{
        name: attrs["name"] || school.name,
        region_id: attrs["region_id"] || school.region_id,
        type: attrs["type"] || school.type,
        students: parse_integer(attrs["students"]) || school.students || 0,
        address: attrs["address"] || school.address || "",
        phone: attrs["phone"] || school.phone || "",
        email: attrs["email"] || school.email || "",
        website: attrs["website"] || school.website || "",
        description: attrs["description"] || school.description || ""
      }
      
      updated_school = Map.merge(school, attrs_atom)
      {:ok, updated_school}
    end
  end

  defp parse_integer(nil), do: nil
  defp parse_integer(val) when is_integer(val), do: val
  defp parse_integer(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> int
      :error -> nil
    end
  end
  defp parse_integer(_), do: nil

  defp delete_school(school) do
    if Map.has_key?(school, :__struct__) && school.__struct__ == School do
      Repo.delete(school)
    else
      # For mock data, just return ok
      {:ok, school}
    end
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
                <.link
                  navigate={~p"/regions/#{@region.id}/schools"}
                  class="text-sm font-medium text-base-content/60 hover:text-base-content"
                >
                  {@region.name}
                </.link>
              </div>
            </li>
            <li>
              <div class="flex items-center">
                <.icon name="hero-chevron-right" class="w-4 h-4 text-base-content/40 mx-1" />
                <span class="text-sm font-medium text-base-content">{@school.name}</span>
              </div>
            </li>
          </ol>
        </nav>

        <!-- Header -->
        <header class="mb-8">
          <div class="flex items-center justify-between">
            <div class="flex-1">
              <h1 class="text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
                {@school.name}
              </h1>
              <p class="mt-2 text-base text-base-content/70">
                {@school.type} • {@region.name}
              </p>
            </div>
            <div class="flex items-center gap-3">
              <span class="badge badge-primary badge-lg">
                {@school.students} {gettext("students")}
              </span>
              <button
                :if={!@editing}
                phx-click="edit"
                class="btn btn-primary"
              >
                <.icon name="hero-pencil" class="w-5 h-5 mr-2" />
                {gettext("Edit")}
              </button>
              <button
                :if={@editing}
                phx-click="cancel_edit"
                class="btn btn-ghost"
              >
                {gettext("Cancel")}
              </button>
            </div>
          </div>
        </header>

        <!-- School Details -->
        <div :if={!@editing} class="grid gap-6 lg:grid-cols-3">
          <!-- Main Info -->
          <div class="lg:col-span-2 space-y-6">
            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
              <h2 class="text-xl font-bold text-base-content mb-6">
                {gettext("School Information")}
              </h2>
              <div class="space-y-4">
                <div>
                  <label class="text-sm font-semibold text-base-content/60">
                    {gettext("Name")}
                  </label>
                  <p class="text-base text-base-content mt-1">{@school.name}</p>
                </div>
                <div>
                  <label class="text-sm font-semibold text-base-content/60">
                    {gettext("Type")}
                  </label>
                  <p class="text-base text-base-content mt-1">{@school.type}</p>
                </div>
                <div :if={@school.description}>
                  <label class="text-sm font-semibold text-base-content/60">
                    {gettext("Description")}
                  </label>
                  <p class="text-base text-base-content mt-1">{@school.description}</p>
                </div>
              </div>
            </div>

            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
              <h2 class="text-xl font-bold text-base-content mb-6">
                {gettext("Contact Information")}
              </h2>
              <div class="space-y-4">
                <div :if={@school.address}>
                  <label class="text-sm font-semibold text-base-content/60 flex items-center gap-2">
                    <.icon name="hero-map-pin" class="w-4 h-4" />
                    {gettext("Address")}
                  </label>
                  <p class="text-base text-base-content mt-1">{@school.address}</p>
                </div>
                <div :if={@school.phone}>
                  <label class="text-sm font-semibold text-base-content/60 flex items-center gap-2">
                    <.icon name="hero-phone" class="w-4 h-4" />
                    {gettext("Phone")}
                  </label>
                  <p class="text-base text-base-content mt-1">
                    <.link href={"tel:#{@school.phone}"} class="link link-primary">
                      {@school.phone}
                    </.link>
                  </p>
                </div>
                <div :if={@school.email}>
                  <label class="text-sm font-semibold text-base-content/60 flex items-center gap-2">
                    <.icon name="hero-envelope" class="w-4 h-4" />
                    {gettext("Email")}
                  </label>
                  <p class="text-base text-base-content mt-1">
                    <.link href={"mailto:#{@school.email}"} class="link link-primary">
                      {@school.email}
                    </.link>
                  </p>
                </div>
                <div :if={@school.website}>
                  <label class="text-sm font-semibold text-base-content/60 flex items-center gap-2">
                    <.icon name="hero-globe-alt" class="w-4 h-4" />
                    {gettext("Website")}
                  </label>
                  <p class="text-base text-base-content mt-1">
                    <.link href={@school.website} target="_blank" class="link link-primary">
                      {@school.website}
                    </.link>
                  </p>
                </div>
              </div>
            </div>
          </div>

          <!-- Sidebar -->
          <div class="lg:col-span-1 space-y-6">
            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm">
              <h3 class="text-lg font-bold text-base-content mb-4">
                {gettext("Quick Stats")}
              </h3>
              <div class="space-y-3">
                <div class="flex items-center justify-between">
                  <span class="text-sm text-base-content/70">{gettext("Students")}</span>
                  <span class="text-lg font-bold text-base-content">{@school.students}</span>
                </div>
                <div class="flex items-center justify-between">
                  <span class="text-sm text-base-content/70">{gettext("Region")}</span>
                  <span class="text-lg font-bold text-base-content">{@region.name}</span>
                </div>
                <div class="flex items-center justify-between">
                  <span class="text-sm text-base-content/70">{gettext("Type")}</span>
                  <span class="text-lg font-bold text-base-content">{@school.type}</span>
                </div>
              </div>
            </div>

            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm">
              <h3 class="text-lg font-bold text-base-content mb-4">
                {gettext("Actions")}
              </h3>
              <div class="space-y-2">
                <button
                  phx-click="delete"
                  data-confirm={gettext("Are you sure you want to delete this school?")}
                  class="btn btn-error btn-block"
                >
                  <.icon name="hero-trash" class="w-4 h-4 mr-2" />
                  {gettext("Delete School")}
                </button>
                <.link
                  navigate={~p"/regions/#{@region.id}/schools"}
                  class="btn btn-outline btn-block"
                >
                  <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" />
                  {gettext("Back to Schools")}
                </.link>
              </div>
            </div>
          </div>
        </div>

        <!-- Edit Form -->
        <div :if={@editing} class="max-w-3xl">
          <form phx-submit="save" phx-change="validate" class="space-y-6">
            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
              <h2 class="text-xl font-bold text-base-content mb-6">
                {gettext("Edit School")}
              </h2>

              <div class="space-y-4">
                <.input
                  field={@form[:name]}
                  type="text"
                  label={gettext("School Name")}
                  required
                />

                <.input
                  field={@form[:type]}
                  type="text"
                  label={gettext("School Type")}
                  required
                />

                <.input
                  field={@form[:students]}
                  type="number"
                  label={gettext("Number of Students")}
                  min="0"
                />

                <.input
                  field={@form[:address]}
                  type="text"
                  label={gettext("Address")}
                />

                <.input
                  field={@form[:phone]}
                  type="tel"
                  label={gettext("Phone")}
                />

                <.input
                  field={@form[:email]}
                  type="email"
                  label={gettext("Email")}
                />

                <.input
                  field={@form[:website]}
                  type="url"
                  label={gettext("Website")}
                />

                <.input
                  field={@form[:description]}
                  type="textarea"
                  label={gettext("Description")}
                />
              </div>

              <div class="mt-6 flex justify-end gap-3">
                <button
                  type="button"
                  phx-click="cancel_edit"
                  class="btn btn-ghost"
                >
                  {gettext("Cancel")}
                </button>
                <button type="submit" class="btn btn-primary">
                  {gettext("Save Changes")}
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

