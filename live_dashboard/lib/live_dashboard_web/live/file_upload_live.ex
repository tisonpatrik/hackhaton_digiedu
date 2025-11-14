defmodule LiveDashboardWeb.FileUploadLive do
  use LiveDashboardWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    # Set locale from session
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    socket =
      socket
      |> assign(:uploaded_files, [])
      |> assign(:processing, false)
      |> assign(:error_message, nil)
      |> allow_upload(:file, accept: :any, max_entries: 1, max_file_size: 500_000_000, chunk_size: 64_000)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("upload", _params, socket) do
    # Set processing state
    socket = assign(socket, :processing, true)
    socket = assign(socket, :error_message, nil)

    uploaded_files =
      consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
        # Read the file
        file_binary = File.read!(path)
        filename = entry.client_name

        # Call the Rust API
        case upload_to_api(file_binary, filename) do
          {:ok, response} ->
            {:ok, Map.put(response, "original_name", filename)}

          {:error, reason} ->
            {:postpone, {:error, reason}}
        end
      end)

    case uploaded_files do
      [result | _] when is_map(result) ->
        socket =
          socket
          |> assign(:uploaded_files, [result | socket.assigns.uploaded_files])
          |> assign(:processing, false)
          |> assign(:error_message, nil)

        {:noreply, socket}

      [] ->
        {:noreply, assign(socket, :processing, false)}

      [{:error, reason} | _] ->
        socket =
          socket
          |> assign(:processing, false)
          |> assign(:error_message, reason)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("clear-error", _params, socket) do
    {:noreply, assign(socket, :error_message, nil)}
  end

  defp upload_to_api(file_binary, filename) do
    api_url = System.get_env("DATA_PROCESSING_URL", "http://localhost:8080")

    # Create multipart form data
    boundary = "----WebKitFormBoundary#{:rand.uniform(1_000_000_000)}"
    
    content_type = get_content_type(filename)
    
    # Build multipart body manually
    body = 
      "--#{boundary}\r\n" <>
      "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n" <>
      "Content-Type: #{content_type}\r\n\r\n" <>
      file_binary <>
      "\r\n--#{boundary}--\r\n"

    # Increase timeout for large files (10 minutes)
    case Req.post("#{api_url}/upload",
           body: body,
           headers: [{"content-type", "multipart/form-data; boundary=#{boundary}"}],
           receive_timeout: 600_000,
           retry: false) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        error_msg =
          if is_map(body) and Map.has_key?(body, "error") do
            body["error"]
          else
            "Upload failed with status #{status}"
          end

        {:error, error_msg}

      {:error, exception} ->
        {:error, Exception.message(exception)}
    end
  end

  defp get_content_type(filename) do
    case Path.extname(filename) |> String.downcase() do
      ".mp3" -> "audio/mpeg"
      ".wav" -> "audio/wav"
      ".ogg" -> "audio/ogg"
      ".m4a" -> "audio/mp4"
      ".flac" -> "audio/flac"
      ".txt" -> "text/plain"
      ".pdf" -> "application/pdf"
      ".json" -> "application/json"
      _ -> "application/octet-stream"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash}>
      <section class="px-6 py-10 sm:px-10 lg:px-16 xl:px-20">
        <header class="flex flex-col gap-6 rounded-3xl bg-gradient-to-br from-primary/10 via-primary/5 to-base-100 px-8 py-10 shadow-lg">
          <div>
            <p class="text-sm font-semibold uppercase tracking-[0.35em] text-primary/70">
              {gettext("Data Processing")}
            </p>
            <h1 class="mt-3 text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
              {gettext("File Upload & Analysis")}
            </h1>
            <p class="mt-4 max-w-xl text-base leading-7 text-base-content/70">
              {gettext(
                "Upload audio files for automatic transcription or other files for processing. This demonstrates our educational data processing capabilities."
              )}
            </p>
          </div>
        </header>

        <div class="mt-12 grid gap-6 lg:grid-cols-2">
          <!-- Upload Section -->
          <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
            <h2 class="text-xl font-bold text-base-content mb-6">
              {gettext("Upload File")}
            </h2>

            <form phx-submit="upload" phx-change="validate" class="space-y-6">
              <div
                class="relative rounded-2xl border-2 border-dashed border-base-300 bg-base-200/30 p-12 text-center hover:border-primary/50 transition-colors"
                phx-drop-target={@uploads.file.ref}
              >
                <.icon name="hero-cloud-arrow-up" class="mx-auto h-12 w-12 text-base-content/40" />
                <div class="mt-4">
                  <label
                    for={@uploads.file.ref}
                    class="cursor-pointer text-sm font-semibold text-primary hover:text-primary/80"
                  >
                    {gettext("Choose a file")}
                    <.live_file_input upload={@uploads.file} class="sr-only" />
                  </label>
                  <span class="text-sm text-base-content/60">
                    {gettext(" or drag and drop")}
                  </span>
                </div>
                <p class="mt-2 text-xs text-base-content/50">
                  {gettext("Audio files will be automatically transcribed")}
                </p>
              </div>

              <!-- File preview -->
              <%= for entry <- @uploads.file.entries do %>
                <div class="flex items-center gap-4 rounded-xl bg-base-200/50 p-4">
                  <.icon name="hero-document" class="h-8 w-8 text-primary" />
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-semibold text-base-content truncate">
                      <%= entry.client_name %>
                    </p>
                    <p class="text-xs text-base-content/60">
                      <%= Float.round(entry.client_size / 1_000_000, 2) %> MB
                    </p>
                  </div>
                  <button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    class="btn btn-ghost btn-sm btn-circle"
                  >
                    <.icon name="hero-x-mark" class="h-5 w-5" />
                  </button>
                </div>

                <!-- Progress bar -->
                <div class="w-full bg-base-300 rounded-full h-2">
                  <div
                    class="bg-primary h-2 rounded-full transition-all duration-300"
                    style={"width: #{entry.progress}%"}
                  >
                  </div>
                </div>
              <% end %>

              <!-- Error Messages -->
              <%= if @error_message do %>
                <div class="alert alert-error">
                  <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
                  <span><%= @error_message %></span>
                  <button
                    type="button"
                    phx-click="clear-error"
                    class="btn btn-ghost btn-sm btn-circle"
                  >
                    <.icon name="hero-x-mark" class="h-5 w-5" />
                  </button>
                </div>
              <% end %>

              <!-- Upload errors -->
              <%= for err <- upload_errors(@uploads.file) do %>
                <div class="alert alert-error">
                  <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
                  <span><%= error_to_string(err) %></span>
                </div>
              <% end %>

              <button
                type="submit"
                disabled={@uploads.file.entries == [] or @processing}
                class="btn btn-primary btn-block"
              >
                <%= if @processing do %>
                  <span class="loading loading-spinner"></span>
                  {gettext("Processing...")}
                <% else %>
                  <.icon name="hero-arrow-up-tray" class="h-5 w-5" />
                  {gettext("Upload & Process")}
                <% end %>
              </button>
            </form>
          </div>

          <!-- Results Section -->
          <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
            <h2 class="text-xl font-bold text-base-content mb-6">
              {gettext("Processing Results")}
            </h2>

            <%= if @uploaded_files == [] do %>
              <div class="text-center py-12">
                <.icon name="hero-document-text" class="mx-auto h-16 w-16 text-base-content/20" />
                <p class="mt-4 text-sm text-base-content/60">
                  {gettext("No files processed yet. Upload a file to see results.")}
                </p>
              </div>
            <% else %>
              <div class="space-y-4 max-h-[600px] overflow-y-auto">
                <%= for file <- @uploaded_files do %>
                  <div class="rounded-xl border border-base-300 bg-base-200/30 p-6">
                    <div class="flex items-start gap-3 mb-4">
                      <%= if file["file_type"] == "audio" do %>
                        <.icon name="hero-speaker-wave" class="h-6 w-6 text-primary flex-shrink-0" />
                      <% else %>
                        <.icon name="hero-document" class="h-6 w-6 text-secondary flex-shrink-0" />
                      <% end %>
                      <div class="flex-1 min-w-0">
                        <p class="font-semibold text-base-content truncate">
                          <%= file["original_name"] || file["filename"] %>
                        </p>
                        <p class="text-xs text-base-content/60">
                          Type: <%= file["file_type"] %>
                        </p>
                      </div>
                      <span class="badge badge-success">{gettext("Success")}</span>
                    </div>

                    <%= if file["labels"] && file["labels"] != [] do %>
                      <div class="mt-4 flex flex-wrap gap-2">
                        <p class="text-xs font-semibold uppercase tracking-wide text-base-content/60 w-full mb-1">
                          {gettext("Labels")}:
                        </p>
                        <%= for label <- file["labels"] do %>
                          <span class="badge badge-primary badge-outline gap-1">
                            <.icon name="hero-tag" class="h-3 w-3" />
                            <%= label["name"] %>
                            <span class="badge badge-xs"><%= label["usage_count"] %></span>
                          </span>
                        <% end %>
                      </div>
                    <% end %>

                    <%= if file["transcript_text"] do %>
                      <div class="mt-4 p-4 rounded-lg bg-base-100 border border-base-300">
                        <p class="text-xs font-semibold uppercase tracking-wide text-base-content/60 mb-2">
                          {gettext("Transcription")}
                        </p>
                        <p class="text-sm text-base-content whitespace-pre-wrap max-h-60 overflow-y-auto">
                          <%= file["transcript_text"] %>
                        </p>
                      </div>
                    <% end %>

                    <div class="mt-4 text-xs text-base-content/50">
                      <p>{gettext("Saved to:")} <%= file["file_path"] %></p>
                      <%= if file["transcript_path"] do %>
                        <p>{gettext("Transcript:")} <%= file["transcript_path"] %></p>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </section>
    </Layouts.dashboard>
    """
  end

  defp error_to_string(:too_large), do: gettext("File is too large (max 100MB)")
  defp error_to_string(:not_accepted), do: gettext("File type not accepted")
  defp error_to_string(:too_many_files), do: gettext("Too many files")
  defp error_to_string(_), do: gettext("Unknown error")
end
