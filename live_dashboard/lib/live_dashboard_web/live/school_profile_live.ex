defmodule LiveDashboardWeb.SchoolProfileLive do
  use LiveDashboardWeb, :live_view

  alias LiveDashboard.Repo
  alias LiveDashboard.Schemas.School

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    school = Repo.get!(School, id) |> Repo.preload(municipality: [:region])

    # The live_action is set by the router configuration (:show or :edit)
    live_action = socket.assigns.live_action
    editing = live_action == :edit
    changeset = if editing, do: School.changeset(school, %{}), else: nil
    form = if editing, do: Phoenix.Component.to_form(changeset), else: nil

    socket =
      socket
      |> assign(:school, school)
      |> assign(:page_title, school.name)
      |> assign(:editing, editing)
      |> assign(:changeset, changeset)
      |> assign(:form, form)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id, "edit" => "true"}, _uri, socket) do
    school = Repo.get!(School, id) |> Repo.preload(municipality: [:region])
    changeset = School.changeset(school, %{})

    socket =
      socket
      |> assign(:school, school)
      |> assign(:changeset, changeset)
      |> assign(:editing, true)

    {:noreply, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    school = Repo.get!(School, id) |> Repo.preload(municipality: [:region])

    socket =
      socket
      |> assign(:school, school)
      |> assign(:editing, false)

    {:noreply, socket}
  end

  @impl true
  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash}>
      <div class="max-w-lg mx-auto">
        <!-- Breadcrumbs -->
        <div class="mb-6">
          <nav class="flex" aria-label="Breadcrumb">
            <ol class="flex items-center space-x-2">
              <li>
                <.link navigate={~p"/schools"} class="text-base-content/60 hover:text-base-content">
                  {gettext("Schools")}
                </.link>
              </li>
              <li class="flex items-center">
                <svg class="w-4 h-4 text-base-content/40 mx-2" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fill-rule="evenodd"
                    d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                    clip-rule="evenodd"
                  >
                  </path>
                </svg>
                <.link
                  navigate={~p"/schools/#{@school.id}"}
                  class="text-base-content/60 hover:text-base-content"
                >
                  {@school.name}
                </.link>
              </li>
              <li class="flex items-center">
                <svg class="w-4 h-4 text-base-content/40 mx-2" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fill-rule="evenodd"
                    d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                    clip-rule="evenodd"
                  >
                  </path>
                </svg>
                <span class="text-base-content">{gettext("Edit")}</span>
              </li>
            </ol>
          </nav>
        </div>

        <div class="bg-base-100 rounded-3xl p-6 border border-base-300/70">
          <div class="mb-6">
            <h1 class="text-xl font-bold text-base-content">{gettext("Edit School")}</h1>
            <p class="text-base-content/60 mt-1">{gettext("Update school information")}</p>
          </div>

          <.form for={@form} phx-submit="update_school" class="space-y-4">
            <div>
              <label class="label">
                <span class="label-text">{gettext("School Name")}</span>
              </label>
              <.input
                field={@form[:name]}
                class="input input-bordered w-full"
                placeholder={gettext("Enter school name")}
              />
            </div>

            <div>
              <label class="label">
                <span class="label-text">{gettext("School Type")}</span>
              </label>
              <.input
                field={@form[:type]}
                type="select"
                class="select select-bordered w-full"
                prompt={gettext("Select type")}
                options={["Základní škola", "Střední škola", "Gymnázium", "Vysoká škola"]}
              />
            </div>

            <div>
              <label class="label">
                <span class="label-text">{gettext("Number of Students")}</span>
              </label>
              <.input
                field={@form[:students]}
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
                field={@form[:founder]}
                class="input input-bordered w-full"
                placeholder={gettext("Enter founder name")}
              />
            </div>

            <div>
              <label class="label">
                <span class="label-text">{gettext("School Type")}</span>
              </label>
              <.input
                field={@changeset[:type]}
                type="select"
                class="select select-bordered w-full"
                prompt={gettext("Select type")}
                options={["Základní škola", "Střední škola", "Gymnázium", "Vysoká škola"]}
              />
            </div>

            <div>
              <label class="label">
                <span class="label-text">{gettext("Number of Students")}</span>
              </label>
              <.input
                field={@changeset[:students]}
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
                field={@changeset[:founder]}
                class="input input-bordered w-full"
                placeholder={gettext("Enter founder name")}
              />
            </div>

            <div class="flex gap-3 justify-end pt-4">
              <.link navigate={~p"/schools/#{@school.id}"} class="btn btn-ghost btn-sm">
                {gettext("Cancel")}
              </.link>
              <button type="submit" class="btn btn-primary btn-sm">
                <.icon name="hero-check" class="w-4 h-4 mr-2" />
                {gettext("Update")}
              </button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.dashboard>
    """
  end

  @impl true
  def render(%{live_action: :show} = assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash}>
      <div class="max-w-4xl mx-auto">
        <!-- Breadcrumbs -->
        <div class="mb-6">
          <nav class="flex" aria-label="Breadcrumb">
            <ol class="flex items-center space-x-2">
              <li>
                <.link navigate={~p"/schools"} class="text-base-content/60 hover:text-base-content">
                  {gettext("Schools")}
                </.link>
              </li>
              <li class="flex items-center">
                <svg class="w-4 h-4 text-base-content/40 mx-2" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fill-rule="evenodd"
                    d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                    clip-rule="evenodd"
                  >
                  </path>
                </svg>
                <span class="text-base-content">{@school.name}</span>
              </li>
            </ol>
          </nav>
        </div>
        
    <!-- School Header -->
        <div class="bg-base-100 rounded-3xl p-8 mb-8 border border-base-300/70">
          <div class="flex items-start justify-between">
            <div>
              <h1 class="text-3xl font-bold text-base-content mb-2">{@school.name}</h1>
              <p class="text-lg text-base-content/70">
                {@school.municipality.region.name} • {@school.municipality.name}
              </p>
              <p class="text-base-content/60 mt-1">{@school.type}</p>
            </div>
            <div class="flex gap-3">
              <.link navigate={~p"/schools/#{@school.id}/edit"} class="btn btn-primary">
                <.icon name="hero-pencil" class="w-4 h-4 mr-2" />
                {gettext("Edit")}
              </.link>
              <button
                phx-click="delete_school"
                phx-value-id={@school.id}
                class="btn btn-error"
                onclick="return confirm('Are you sure you want to delete this school?')"
              >
                <.icon name="hero-trash" class="w-4 h-4 mr-2" />
                {gettext("Delete")}
              </button>
            </div>
          </div>
        </div>
        
    <!-- School Details -->
        <div class="grid gap-6 md:grid-cols-2">
          <div class="bg-base-100 rounded-3xl p-6 border border-base-300/70">
            <h3 class="text-xl font-semibold mb-4">{gettext("School Information")}</h3>
            <dl class="space-y-3">
              <div>
                <dt class="text-sm font-medium text-base-content/60">{gettext("Name")}</dt>
                <dd class="text-base-content">{@school.name}</dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-base-content/60">{gettext("Type")}</dt>
                <dd class="text-base-content">{@school.type}</dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-base-content/60">{gettext("Students")}</dt>
                <dd class="text-base-content">
                  {if @school.students, do: "#{@school.students} students", else: "Not specified"}
                </dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-base-content/60">{gettext("Founder")}</dt>
                <dd class="text-base-content">{@school.founder || "Not specified"}</dd>
              </div>
            </dl>
          </div>

          <div class="bg-base-100 rounded-3xl p-6 border border-base-300/70">
            <h3 class="text-xl font-semibold mb-4">{gettext("Location")}</h3>
            <dl class="space-y-3">
              <div>
                <dt class="text-sm font-medium text-base-content/60">{gettext("Region")}</dt>
                <dd class="text-base-content">{@school.municipality.region.name}</dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-base-content/60">{gettext("Municipality")}</dt>
                <dd class="text-base-content">{@school.municipality.name}</dd>
              </div>
            </dl>
          </div>
        </div>
        
    <!-- Back Button -->
        <div class="mt-8 text-center">
          <.link navigate={~p"/schools"} class="btn btn-ghost">
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" />
            {gettext("Back to Schools")}
          </.link>
        </div>
      </div>
    </Layouts.dashboard>
    """
  end

  @impl true
  def handle_event("update_school", %{"school" => school_params}, socket) do
    school = socket.assigns.school

    # Handle students field safely
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

    update_params = %{
      name: school_params["name"],
      type: school_params["type"],
      students: students_value,
      founder: school_params["founder"]
    }

    case Repo.update(School.changeset(school, update_params)) do
      {:ok, updated_school} ->
        socket =
          socket
          |> assign(:school, Repo.preload(updated_school, municipality: [:region]))
          |> assign(:editing, false)
          |> put_flash(:info, gettext("School updated successfully!"))

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:changeset, changeset)
          |> put_flash(:error, gettext("Please fix the errors below"))

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_school", %{"id" => id}, socket) do
    school = Repo.get!(School, id)

    case Repo.delete(school) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, gettext("School deleted successfully!"))
          |> push_navigate(to: ~p"/schools")

        {:noreply, socket}

      {:error, %Ecto.Changeset{errors: errors}} ->
        # Handle constraint violations
        error_messages =
          Enum.map(errors, fn {field, {msg, _}} ->
            "#{field}: #{msg}"
          end)
          |> Enum.join(", ")

        socket =
          socket
          |> put_flash(:error, gettext("Cannot delete school: %{errors}", errors: error_messages))

        {:noreply, socket}

      {:error, _} ->
        socket =
          socket
          |> put_flash(:error, gettext("Failed to delete school"))

        {:noreply, socket}
    end
  end
end
