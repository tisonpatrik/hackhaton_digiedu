defmodule LiveDashboardWeb.ConnectLive do
  use LiveDashboardWeb, :live_view

  alias LiveDashboard.{Document, Repo}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:form, to_form(%{}))
      |> allow_upload(:document,
        accept: ~w(.txt .pdf .docx),
        max_entries: 1,
        max_file_size: 10_000_000
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash}>
      <section class="min-h-screen bg-base-200 px-6 py-10 sm:px-10 lg:px-16 xl:px-20">
        <header class="flex flex-col gap-6 rounded-3xl bg-gradient-to-br from-primary/10 via-primary/5 to-base-100 px-8 py-10 shadow-lg transition-shadow duration-300 hover:shadow-xl sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p class="text-sm font-semibold uppercase tracking-[0.35em] text-primary/70">
              Data Integration
            </p>
            <h1 class="mt-3 text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
              Connect Data Sources
            </h1>
            <p class="mt-4 max-w-xl text-base leading-7 text-base-content/70">
              Link your learning platforms, upload documents, or connect APIs to populate the dashboard with real-time data.
            </p>
          </div>
          <div class="flex flex-wrap gap-3">
            <.link
              navigate={~p"/"}
              class="inline-flex items-center gap-2 rounded-2xl bg-base-100 px-5 py-3 text-sm font-semibold text-base-content shadow-sm transition hover:bg-base-300 hover:text-base-content/80 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
            >
              <.icon name="hero-arrow-left" class="h-4 w-4" /> Back to Dashboard
            </.link>
          </div>
        </header>

        <section class="mt-12 space-y-12">
          <div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            <article class="group rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg">
              <div class="flex items-center justify-between mb-6">
                <span class="text-lg font-bold text-base-content">Upload Documents</span>
                <span class="rounded-full bg-primary/10 p-3 text-primary">
                  <.icon name="hero-document-arrow-up" class="h-6 w-6" />
                </span>
              </div>
              <p class="text-sm text-base-content/70 mb-6">
                Upload PDF, DOCX, or TXT files to add to your knowledge base.
              </p>
              <.form for={@form} id="upload-form" phx-submit="upload">
                <.live_file_input
                  upload={@uploads.document}
                  class="file-input file-input-bordered w-full"
                />
                <button
                  type="submit"
                  class="btn btn-primary w-full mt-4"
                  disabled={
                    Enum.empty?(@uploads.document.entries) or
                      Enum.any?(@uploads.document.entries, &(!&1.done?))
                  }
                >
                  Upload File
                </button>
                <%= for entry <- @uploads.document.entries do %>
                  <div class="mt-2">
                    <progress
                      value={entry.progress}
                      max="100"
                      class="progress progress-primary w-full"
                    >
                    </progress>
                    <p class="text-sm text-base-content/60 mt-1">{entry.progress}% uploaded</p>
                  </div>
                <% end %>
              </.form>
            </article>

            <article class="group rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg">
              <div class="flex items-center justify-between mb-6">
                <span class="text-lg font-bold text-base-content">API Integration</span>
                <span class="rounded-full bg-secondary/10 p-3 text-secondary">
                  <.icon name="hero-cloud-arrow-up" class="h-6 w-6" />
                </span>
              </div>
              <p class="text-sm text-base-content/70 mb-6">
                Connect to learning management systems like Moodle or Canvas.
              </p>
              <button class="btn btn-secondary w-full">Connect API</button>
            </article>

            <article class="group rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg">
              <div class="flex items-center justify-between mb-6">
                <span class="text-lg font-bold text-base-content">Database Sync</span>
                <span class="rounded-full bg-accent/10 p-3 text-accent">
                  <.icon name="hero-server-stack" class="h-6 w-6" />
                </span>
              </div>
              <p class="text-sm text-base-content/70 mb-6">
                Sync data from your existing databases or data warehouses.
              </p>
              <button class="btn btn-accent w-full">Sync Database</button>
            </article>
          </div>
        </section>
      </section>
    </Layouts.dashboard>
    """
  end

  @impl true
  def handle_event("upload", _params, socket) do
    File.mkdir_p("files")

    uploaded_files =
      consume_uploaded_entries(socket, :document, fn %{path: path}, entry ->
        ext = Path.extname(entry.client_name)
        filename = "#{System.unique_integer([:positive])}#{ext}"
        destination = "files/#{filename}"
        File.cp!(path, destination)

        %Document{}
        |> Document.changeset(%{document_name: entry.client_name, file_path: destination})
        |> Repo.insert()
      end)

    case uploaded_files do
      [ok: _] ->
        {:noreply, socket |> put_flash(:info, "Document uploaded successfully")}

      _ ->
        {:noreply, socket |> put_flash(:error, "Upload failed")}
    end
  end
end
