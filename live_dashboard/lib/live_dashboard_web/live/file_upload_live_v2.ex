defmodule LiveDashboardWeb.FileUploadLiveV2 do
  use LiveDashboardWeb, :live_view
  alias LiveDashboard.FileJobs

  @impl true
  def mount(_params, session, socket) do
    # Set locale from session
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    # Subscribe to job updates
    if connected?(socket) do
      FileJobs.subscribe()
      send(self(), :refresh_jobs)
    end

    socket =
      socket
      |> assign(:jobs, [])
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
    socket = assign(socket, :error_message, nil)

    uploaded_files =
      consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
        # Read the file
        file_binary = File.read!(path)
        filename = entry.client_name
        file_size = byte_size(file_binary)

        # Determine file type
        file_type = cond do
          is_audio_file?(filename) -> "audio"
          is_image_file?(filename) -> "image"
          is_text_file?(filename) -> "text"
          is_tabular_file?(filename) -> "tabular"
          true -> "other"
        end

        # Create job in database
        case FileJobs.create_job(%{
          filename: filename,
          file_type: file_type,
          file_size: file_size,
          status: "pending"
        }) do
          {:ok, job} ->
            # Process file in background
            Task.start(fn ->
              process_file_job(job.id, file_binary, filename, file_type)
            end)

            {:ok, job}

          {:error, _changeset} ->
            {:postpone, {:error, "Failed to create job"}}
        end
      end)

    case uploaded_files do
      [result | _] when is_map(result) ->
        # Refresh jobs list
        send(self(), :refresh_jobs)
        {:noreply, socket}

      [] ->
        {:noreply, socket}

      [{:error, reason} | _] ->
        socket = assign(socket, :error_message, reason)
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("clear-error", _params, socket) do
    {:noreply, assign(socket, :error_message, nil)}
  end

  @impl true
  def handle_info(:refresh_jobs, socket) do
    jobs = FileJobs.list_jobs(20)
    {:noreply, assign(socket, :jobs, jobs)}
  end

  @impl true
  def handle_info({:job_updated, _job}, socket) do
    # Refresh jobs when any job is updated
    send(self(), :refresh_jobs)
    {:noreply, socket}
  end

  defp process_file_job(job_id, file_binary, filename, file_type) do
    # Stage 0: Uploaded
    FileJobs.update_job_status(job_id, "processing", %{progress: 0})
    FileJobs.broadcast_job_update(%{id: job_id})
    Process.sleep(1500)  # Show stage for visibility

    api_url = System.get_env("DATA_PROCESSING_URL", "http://data_processing:8080")

    # Create multipart form data
    boundary = "----WebKitFormBoundary#{:rand.uniform(1_000_000_000)}"
    content_type = get_content_type(filename)

    body =
      "--#{boundary}\r\n" <>
        "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n" <>
        "Content-Type: #{content_type}\r\n\r\n" <>
        file_binary <>
        "\r\n--#{boundary}--\r\n"

    # Stage 1: Preparing (API will handle preprocessing)
    FileJobs.update_job_status(job_id, "processing", %{progress: 1})
    FileJobs.broadcast_job_update(%{id: job_id})
    # Images process faster, so shorter delay
    sleep_time = if file_type == "image", do: 1000, else: 2000
    Process.sleep(sleep_time)

    # Stage 2: Processing (transcribing/analyzing - send to API)
    FileJobs.update_job_status(job_id, "processing", %{progress: 2})
    FileJobs.broadcast_job_update(%{id: job_id})

    # Upload to API
    case Req.post("#{api_url}/upload",
           body: body,
           headers: [{"content-type", "multipart/form-data; boundary=#{boundary}"}],
           receive_timeout: 1_200_000,  # 20 minutes for very long files
           retry: false
         ) do
      {:ok, %{status: 200, body: response}} ->
        # Stage 3: Finalizing
        FileJobs.update_job_status(job_id, "processing", %{progress: 3})
        FileJobs.broadcast_job_update(%{id: job_id})
        Process.sleep(1500)  # Show stage for visibility
        
        # Success
        FileJobs.update_job_status(job_id, "completed", %{
          progress: 3,
          result_path: response["file_path"],
          transcript_text: response["transcript_text"]
        })

        FileJobs.broadcast_job_update(%{id: job_id})

      {:ok, %{status: status, body: body}} ->
        error_msg =
          if is_map(body) and Map.has_key?(body, "error") do
            body["error"]
          else
            "Upload failed with status #{status}"
          end

        FileJobs.update_job_status(job_id, "failed", %{error_message: error_msg})
        FileJobs.broadcast_job_update(%{id: job_id})

      {:error, exception} ->
        FileJobs.update_job_status(job_id, "failed", %{
          error_message: Exception.message(exception)
        })

        FileJobs.broadcast_job_update(%{id: job_id})
    end
  end

  defp is_audio_file?(filename) do
    ext = Path.extname(filename) |> String.downcase()

    ext in [".mp3", ".wav", ".ogg", ".flac", ".m4a", ".aac", ".wma", ".opus"]
  end

  defp is_image_file?(filename) do
    ext = Path.extname(filename) |> String.downcase()

    ext in [".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".tiff", ".tif"]
  end

  defp is_text_file?(filename) do
    ext = Path.extname(filename) |> String.downcase()

    ext in [".txt", ".md", ".log", ".doc", ".docx"]
  end

  defp is_tabular_file?(filename) do
    ext = Path.extname(filename) |> String.downcase()

    ext in [".csv", ".xlsx", ".xls", ".tsv", ".ods", ".json", ".yml", ".yaml"]
  end

  defp get_content_type(filename) do
    case Path.extname(filename) |> String.downcase() do
      ".mp3" -> "audio/mpeg"
      ".wav" -> "audio/wav"
      ".ogg" -> "audio/ogg"
      ".m4a" -> "audio/mp4"
      ".flac" -> "audio/flac"
      ".png" -> "image/png"
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".gif" -> "image/gif"
      ".webp" -> "image/webp"
      ".bmp" -> "image/bmp"
      ".tiff" -> "image/tiff"
      ".tif" -> "image/tiff"
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
              {gettext("File Upload & Processing Queue")}
            </h1>
            <p class="mt-4 max-w-xl text-base leading-7 text-base-content/70">
              {gettext(
                "Upload educational files for processing. Audio files will be transcribed, images analyzed with AI vision, text and tables extracted automatically."
              )}
            </p>
          </div>
        </header>

        <div class="mt-12 grid gap-6 lg:grid-cols-3">
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
                  {gettext("All file types supported: audio, images, text, tables")}
                </p>
              </div>

              <!-- File preview -->
              <%= for entry <- @uploads.file.entries do %>
                <div class="space-y-3">
                  <%= if is_image_file?(entry.client_name) do %>
                    <!-- Image preview -->
                    <div class="relative rounded-xl overflow-hidden bg-base-200/50 p-2">
                      <.live_img_preview entry={entry} class="w-full h-48 object-contain rounded-lg" />
                      <button
                        type="button"
                        phx-click="cancel-upload"
                        phx-value-ref={entry.ref}
                        class="absolute top-3 right-3 btn btn-ghost btn-sm btn-circle bg-base-100/80 hover:bg-base-100"
                      >
                        <.icon name="hero-x-mark" class="h-5 w-5" />
                      </button>
                    </div>
                  <% else %>
                    <!-- Regular file preview -->
                    <div class="flex items-center gap-4 rounded-xl bg-base-200/50 p-4">
                      <%= if is_audio_file?(entry.client_name) do %>
                        <.icon name="hero-speaker-wave" class="h-8 w-8 text-primary" />
                      <% else %>
                        <.icon name="hero-document" class="h-8 w-8 text-secondary" />
                      <% end %>
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
                  <% end %>

                  <!-- File name and size for images -->
                  <%= if is_image_file?(entry.client_name) do %>
                    <div class="flex items-center justify-between px-2">
                      <p class="text-sm font-semibold text-base-content truncate flex-1">
                        <%= entry.client_name %>
                      </p>
                      <p class="text-xs text-base-content/60">
                        <%= Float.round(entry.client_size / 1_000_000, 2) %> MB
                      </p>
                    </div>
                  <% end %>

                  <!-- Progress bar -->
                  <div class="w-full bg-base-300 rounded-full h-2">
                    <div
                      class="bg-primary h-2 rounded-full transition-all duration-300"
                      style={"width: #{entry.progress}%"}
                    >
                    </div>
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
                disabled={@uploads.file.entries == []}
                class="btn btn-primary btn-block"
              >
                <.icon name="hero-arrow-up-tray" class="h-5 w-5" />
                {gettext("Upload File")}
              </button>
            </form>
          </div>

          <!-- Processing Queue -->
          <div class="lg:col-span-2 rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
            <h2 class="text-xl font-bold text-base-content mb-6">
              {gettext("Processing Queue")}
            </h2>

            <%= if @jobs == [] do %>
              <div class="text-center py-12">
                <.icon name="hero-queue-list" class="mx-auto h-16 w-16 text-base-content/20" />
                <p class="mt-4 text-sm text-base-content/60">
                  {gettext("No files in queue. Upload a file to start processing.")}
                </p>
              </div>
            <% else %>
              <div class="space-y-4 max-h-[600px] overflow-y-auto">
                <%= for job <- @jobs do %>
                  <div class="rounded-xl border border-base-300 bg-base-200/30 p-6">
                    <div class="flex items-start gap-3 mb-4">
                      <%= cond do %>
                        <% job.file_type == "audio" -> %>
                          <.icon name="hero-speaker-wave" class="h-6 w-6 text-primary flex-shrink-0" />
                        <% job.file_type == "image" -> %>
                          <.icon name="hero-photo" class="h-6 w-6 text-accent flex-shrink-0" />
                        <% job.file_type == "text" -> %>
                          <.icon name="hero-document-text" class="h-6 w-6 text-info flex-shrink-0" />
                        <% job.file_type == "tabular" -> %>
                          <.icon name="hero-table-cells" class="h-6 w-6 text-success flex-shrink-0" />
                        <% true -> %>
                          <.icon name="hero-document" class="h-6 w-6 text-secondary flex-shrink-0" />
                      <% end %>
                      <div class="flex-1 min-w-0">
                        <p class="font-semibold text-base-content truncate">
                          <%= job.filename %>
                        </p>
                        <p class="text-xs text-base-content/60">
                          <%= Float.round(job.file_size / 1_000_000, 2) %> MB · <%= job.file_type %>
                        </p>
                      </div>
                      <span class={[
                        "badge",
                        job.status == "completed" && "badge-success",
                        job.status == "processing" && "badge-warning",
                        job.status == "failed" && "badge-error",
                        job.status == "pending" && "badge-info"
                      ]}>
                        <%= job.status %>
                      </span>
                    </div>

                    <!-- Progress stages -->
                    <%= if job.status in ["pending", "processing"] do %>
                      <div class="mb-4">
                        <div class="flex justify-between text-xs text-base-content/60 mb-2">
                          <span><%= LiveDashboard.FileJobs.Job.stage_name(job.progress, job.file_type) %></span>
                          <span class="loading loading-spinner loading-xs"></span>
                        </div>
                        <div class="flex gap-1">
                          <%= for stage <- 0..3 do %>
                            <div class={[
                              "flex-1 h-2 rounded transition-all duration-300",
                              stage <= job.progress && "bg-warning",
                              stage > job.progress && "bg-base-300"
                            ]} />
                          <% end %>
                        </div>
                      </div>
                    <% end %>

                    <%= if job.transcript_text do %>
                      <div class="mt-4 p-4 rounded-lg bg-base-100 border border-base-300">
                        <p class="text-xs font-semibold uppercase tracking-wide text-base-content/60 mb-2">
                          <%= cond do %>
                            <% job.file_type == "audio" -> %> {gettext("Transcription")}
                            <% job.file_type == "image" -> %> {gettext("Image Analysis")}
                            <% job.file_type == "text" -> %> {gettext("Extracted Text")}
                            <% job.file_type == "tabular" -> %> {gettext("Extracted Data")}
                            <% true -> %> {gettext("Content")}
                          <% end %>
                        </p>
                        <p class="text-sm text-base-content whitespace-pre-wrap max-h-40 overflow-y-auto">
                          <%= job.transcript_text %>
                        </p>
                      </div>
                    <% end %>

                    <%= if job.error_message do %>
                      <div class="mt-4 p-4 rounded-lg bg-error/10 border border-error/20">
                        <p class="text-xs font-semibold uppercase tracking-wide text-error mb-2">
                          {gettext("Error")}
                        </p>
                        <p class="text-sm text-error">
                          <%= job.error_message %>
                        </p>
                      </div>
                    <% end %>

                    <div class="mt-4 text-xs text-base-content/50">
                      <p>
                        {gettext("Started:")}
                        <%= Calendar.strftime(job.inserted_at, "%Y-%m-%d %H:%M:%S") %>
                      </p>
                      <%= if job.result_path do %>
                        <p class="mt-1">{gettext("Result:")} <%= job.result_path %></p>
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

  defp error_to_string(:too_large), do: gettext("File is too large (max 500MB)")
  defp error_to_string(:not_accepted), do: gettext("File type not accepted")
  defp error_to_string(:too_many_files), do: gettext("Too many files")
  defp error_to_string(_), do: gettext("Unknown error")
end
