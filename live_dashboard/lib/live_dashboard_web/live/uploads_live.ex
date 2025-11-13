defmodule LiveDashboardWeb.UploadLive do
  use LiveDashboardWeb, :live_view

  # Allowed extensions as a LIST (important)
  @accept ~w(
    .jpg .jpeg .pdf .png .gif
    .mp4 .mp3 .wav
    .txt .zip
    .doc .docx .xls .xlsx .ppt .pptx .csv
  )

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> allow_upload(:files,
        accept: @accept,
        max_entries: 100,
        max_file_size: 24 * 1024 * 1024, # 24 MB
        auto_upload: false
      )
      |> assign(:uploaded_files, [])

    {:ok, socket}
  end

  @spec handle_event(<<_::32, _::_*72>>, any(), Phoenix.LiveView.Socket.t()) :: {:noreply, map()}
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :files, fn %{path: tmp_path}, entry ->
        # Store files inside priv/static/uploads so they can be served as /uploads/...
        dest_dir = Application.app_dir(:live_dashboard, "priv/static/uploads")
        File.mkdir_p!(dest_dir)

        dest = Path.join(dest_dir, entry.client_name)
        File.cp!(tmp_path, dest)

        {:ok, %{name: entry.client_name, size: entry.client_size}}
      end)

    {:noreply,
     socket
     |> assign(:uploaded_files, socket.assigns.uploaded_files ++ uploaded_files)}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-950 text-slate-100 flex items-center justify-center px-4">
      <div class="w-full max-w-4xl">
        <div class="bg-slate-900 border border-slate-800 rounded-2xl shadow-xl p-6 md:p-8">
          <h1 class="text-2xl md:text-3xl font-semibold tracking-tight mb-2">
            File upload
          </h1>
          <p class="text-sm text-slate-400 mb-6">
            Drag & drop files here or click to select. Supports images, docs, audio, video and archives.
          </p>

          <.upload_form uploads={@uploads} />
          <.upload_entries uploads={@uploads} />
          <.uploaded_list uploaded_files={@uploaded_files} />
        </div>
      </div>
    </div>
    """
  end

  # ──────────────────────
  # Components
  # ──────────────────────

  # Upload form with drag & drop area
  attr :uploads, :map, required: true
  defp upload_form(assigns) do
    ~H"""
    <form phx-submit="save" phx-change="validate">
      <!-- Dropzone -->
      <label
        for={"files-input"}
        phx-drop-target={@uploads.files.ref}
        class="flex flex-col items-center justify-center w-full border-2 border-dashed border-slate-700 hover:border-indigo-500/70 transition-colors rounded-xl p-8 cursor-pointer bg-slate-900/60"
      >
        <div class="flex flex-col items-center justify-center text-center space-y-3">
          <!-- Icon -->
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
               fill="none" stroke="currentColor" stroke-width="1.5"
               class="w-12 h-12 text-indigo-400/90">
            <path stroke-linecap="round" stroke-linejoin="round"
                  d="M3 15.75h16.5M3 15.75a3 3 0 0 1 3-3h3m10.5 3a3 3 0 0 0-3-3h-3m-4.5 0V4.5m0 8.25-2.25-2.25M9 12.75l2.25-2.25" />
          </svg>

          <div>
            <p class="text-sm font-medium">
              <span class="text-indigo-400">Click to upload</span> or drag and drop
            </p>
            <p class="text-xs text-slate-400 mt-1">
              Max 24 MB per file • up to 100 files
            </p>
          </div>

          <p class="text-[10px] text-slate-500 max-w-md">
            Allowed: <%= @uploads.files.accept %>
          </p>
        </div>

        <!-- Actual live file input (hidden visually but clickable via label) -->
        <.live_file_input
          id="files-input"
          upload={@uploads.files}
          class="sr-only"
        />
      </label>

      <div class="flex justify-end mt-4">
        <button
          type="submit"
          class="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-indigo-500 hover:bg-indigo-400 text-sm font-medium shadow-md shadow-indigo-500/20 disabled:opacity-40 disabled:cursor-not-allowed transition-all"
          disabled={Enum.empty?(@uploads.files.entries)}
        >
          <span>Upload</span>
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
               fill="none" stroke="currentColor" stroke-width="1.5"
               class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round"
                  d="M4.5 19.5l15-15m0 0h-9m9 0v9" />
          </svg>
        </button>
      </div>
    </form>
    """
  end

  # List of currently selected entries (before save)
  attr :uploads, :map, required: true
  defp upload_entries(assigns) do
    ~H"""
    <%= if @uploads.files.entries != [] do %>
      <div class="mt-6 space-y-3">
        <h2 class="text-sm font-medium text-slate-300">
          Pending uploads
        </h2>

        <%= for entry <- @uploads.files.entries do %>
          <div class="rounded-xl border border-slate-800 bg-slate-900/80 p-3 flex flex-col gap-2">
            <div class="flex items-center justify-between gap-3">
              <div class="flex items-center gap-3 min-w-0">
                <!-- Small file icon -->
                <div class="w-9 h-9 rounded-lg bg-slate-800 flex items-center justify-center flex-shrink-0">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                       fill="none" stroke="currentColor" stroke-width="1.5"
                       class="w-5 h-5 text-slate-300">
                    <path stroke-linecap="round" stroke-linejoin="round"
                          d="M9 6.75H7.5A2.25 2.25 0 0 0 5.25 9v9A2.25 2.25 0 0 0 7.5 20.25h9A2.25 2.25 0 0 0 18.75 18v-9A2.25 2.25 0 0 0 16.5 6.75H15M9 6.75A2.25 2.25 0 0 0 11.25 4.5h1.5A2.25 2.25 0 0 1 15 6.75M9 6.75H15" />
                  </svg>
                </div>

                <div class="min-w-0">
                  <p class="text-xs font-medium truncate">
                    <%= entry.client_name %>
                  </p>
                  <p class="text-[10px] text-slate-500">
                    <%= format_bytes(entry.client_size || 0) %>
                  </p>
                </div>
              </div>

              <div class="flex items-center gap-2 flex-shrink-0">
                <%= if entry.done? do %>
                  <span class="text-[10px] px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/30">
                    Ready
                  </span>
                <% else %>
                  <span class="text-[10px] px-2 py-0.5 rounded-full bg-indigo-500/10 text-indigo-300 border border-indigo-500/30">
                    <%= entry.progress %>%
                  </span>
                <% end %>

                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  class="text-[10px] px-2 py-1 rounded-md border border-slate-700 hover:border-red-500 hover:text-red-400 transition-colors"
                >
                  Cancel
                </button>
              </div>
            </div>

            <!-- Progress bar -->
            <div class="w-full h-1.5 bg-slate-800 rounded-full overflow-hidden">
              <div
                class="h-1.5 rounded-full bg-indigo-500 transition-all"
                style={"width: #{entry.progress}%"}
              >
              </div>
            </div>

            <!-- Image preview if it's an image -->
            <%= if image_entry?(entry) do %>
              <div class="mt-1">
                <.live_img_preview
                  entry={entry}
                  class="max-h-32 rounded-lg border border-slate-800"
                />
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>
    """
  end

  # List of already uploaded files
  attr :uploaded_files, :list, required: true
  defp uploaded_list(assigns) do
    ~H"""
    <%= if @uploaded_files != [] do %>
      <div class="mt-8 border-t border-slate-800 pt-4">
        <h2 class="text-sm font-medium text-slate-300 mb-3">
          Uploaded files
        </h2>

        <div class="space-y-2 max-h-72 overflow-auto pr-1">
          <%= for file <- @uploaded_files do %>
            <div class="flex items-center justify-between text-xs bg-slate-900/70 border border-slate-800 rounded-lg px-3 py-2">
              <div class="flex items-center gap-2 min-w-0">
                <span class="w-1.5 h-1.5 rounded-full bg-emerald-400 flex-shrink-0"></span>
                <span class="truncate"><%= file.name %></span>
              </div>
              <span class="text-[10px] text-slate-500">
                <%= format_bytes(file.size || 0) %>
              </span>
            </div>
          <% end %>
        </div>

        <p class="text-[10px] text-slate-500 mt-2">
          Files are stored in <code>priv/static/uploads</code> and served from <code>/uploads/</code>.
        </p>
      </div>
    <% end %>
    """
  end

  # ──────────────────────
  # Helpers
  # ──────────────────────

  defp image_entry?(entry) do
    case Path.extname(entry.client_name || "") |> String.downcase() do
      "." <> ext -> ext in ~w(jpg jpeg png gif)
      _ -> false
    end
  end

  defp format_bytes(0), do: "0 B"

  defp format_bytes(bytes) when is_integer(bytes) and bytes > 0 do
    units = ["B", "KB", "MB", "GB", "TB"]

    {value, unit} =
      Enum.reduce_while(units, {bytes * 1.0, "B"}, fn u, {v, _} ->
        cond do
          v < 1024.0 -> {:halt, {v, u}}
          u == List.last(units) -> {:halt, {v, u}}
          true -> {:cont, {v / 1024.0, u}}
        end
      end)

    :erlang.iolist_to_binary(:io_lib.format("~.1f ~s", [value, unit]))
  end
end
