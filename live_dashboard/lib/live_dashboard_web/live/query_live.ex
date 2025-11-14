defmodule LiveDashboardWeb.QueryLive do
  use LiveDashboardWeb, :live_view

  @impl true
  def mount(params, session, socket) do
    # Set locale from session
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    # Pre-fill question from URL params
    initial_question = Map.get(params, "q", "")

    socket =
      socket
      |> assign(:question, initial_question)
      |> assign(:answer, nil)
      |> assign(:selected_labels, [])
      |> assign(:searched_chunks, [])
      |> assign(:loading, false)
      |> assign(:error_message, nil)
      |> assign(:query_history, [])

    # Auto-execute if question provided in URL
    if initial_question != "" && connected?(socket) do
      send(self(), {:execute_query, initial_question})
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("update_question", %{"question" => question}, socket) do
    {:noreply, assign(socket, :question, question)}
  end

  @impl true
  def handle_event("submit_query", %{"question" => question}, socket) do
    if String.trim(question) == "" do
      {:noreply, assign(socket, :error_message, "Please enter a question")}
    else
      socket =
        socket
        |> assign(:loading, true)
        |> assign(:error_message, nil)
      
      send(self(), {:execute_query, question})
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("clear_results", _params, socket) do
    {:noreply, 
     socket
     |> assign(:answer, nil)
     |> assign(:selected_labels, [])
     |> assign(:searched_chunks, [])
     |> assign(:error_message, nil)}
  end

  @impl true
  def handle_info({:execute_query, question}, socket) do
    case query_with_labels(question) do
      {:ok, response} ->
        # Add to history
        history_item = %{
          question: question,
          answer: response["answer"],
          labels: response["selected_labels"],
          timestamp: DateTime.utc_now()
        }
        
        {:noreply,
         socket
         |> assign(:answer, response["answer"])
         |> assign(:selected_labels, response["selected_labels"] || [])
         |> assign(:searched_chunks, response["searched_chunks"] || [])
         |> assign(:loading, false)
         |> assign(:query_history, [history_item | socket.assigns.query_history])}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:error_message, reason)}
    end
  end

  defp query_with_labels(question) do
    api_url = System.get_env("DATA_PROCESSING_URL", "http://localhost:8080")

    case Req.post("#{api_url}/query",
           json: %{question: question},
           receive_timeout: 60_000) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        error_msg =
          if is_map(body) and Map.has_key?(body, "error") do
            body["error"]
          else
            "Query failed with status #{status}"
          end

        {:error, error_msg}

      {:error, exception} ->
        {:error, Exception.message(exception)}
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
              {gettext("AI Assistant")}
            </p>
            <h1 class="mt-3 text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
              {gettext("Ask Questions About Your Data")}
            </h1>
            <p class="mt-4 max-w-xl text-base leading-7 text-base-content/70">
              {gettext(
                "Ask questions and the AI will intelligently select relevant labels and search only the data that matters."
              )}
            </p>
          </div>
        </header>

        <div class="mt-12 grid gap-8 lg:grid-cols-3">
          <!-- Query Section -->
          <div class="lg:col-span-2">
            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-8 shadow-sm">
              <h2 class="text-xl font-bold text-base-content mb-6">
                {gettext("Ask a Question")}
              </h2>

              <form phx-submit="submit_query" class="space-y-4">
                <div>
                  <textarea
                    name="question"
                    value={@question}
                    phx-change="update_question"
                    placeholder={gettext("e.g., What are the students' strengths in mathematics?")}
                    class="textarea textarea-bordered w-full h-32"
                    disabled={@loading}
                  ></textarea>
                </div>

                <%= if @error_message do %>
                  <div class="alert alert-error">
                    <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
                    <span><%= @error_message %></span>
                  </div>
                <% end %>

                <div class="flex gap-4">
                  <button type="submit" class="btn btn-primary flex-1" disabled={@loading}>
                    <%= if @loading do %>
                      <span class="loading loading-spinner"></span>
                      {gettext("Thinking...")}
                    <% else %>
                      <.icon name="hero-sparkles" class="h-5 w-5" />
                      {gettext("Ask Question")}
                    <% end %>
                  </button>
                  <%= if @answer do %>
                    <button type="button" phx-click="clear_results" class="btn btn-ghost">
                      {gettext("Clear")}
                    </button>
                  <% end %>
                </div>
              </form>

              <!-- Answer Section -->
              <%= if @answer do %>
                <div class="mt-8 p-6 rounded-2xl bg-base-200/50 border border-base-300">
                  <div class="flex items-center gap-2 mb-4">
                    <.icon name="hero-light-bulb" class="h-6 w-6 text-primary" />
                    <h3 class="text-lg font-semibold text-base-content">{gettext("Answer")}</h3>
                  </div>
                  <p class="text-base-content whitespace-pre-wrap"><%= @answer %></p>
                </div>

                <!-- Selected Labels -->
                <%= if @selected_labels != [] do %>
                  <div class="mt-6">
                    <p class="text-sm font-semibold text-base-content/60 mb-3">
                      {gettext("Searched in these topics:")}
                    </p>
                    <div class="flex flex-wrap gap-2">
                      <%= for label <- @selected_labels do %>
                        <span class="badge badge-primary badge-lg gap-2">
                          <.icon name="hero-tag" class="h-4 w-4" />
                          <%= label["name"] %>
                        </span>
                      <% end %>
                    </div>
                  </div>
                <% end %>

                <!-- Sources -->
                <%= if @searched_chunks != [] do %>
                  <div class="mt-6">
                    <details class="collapse collapse-arrow bg-base-200/30 border border-base-300">
                      <summary class="collapse-title text-sm font-semibold">
                        {gettext("View sources")} (<%= length(@searched_chunks) %> {gettext("chunks")})
                      </summary>
                      <div class="collapse-content">
                        <div class="space-y-3 mt-2">
                          <%= for chunk <- @searched_chunks do %>
                            <div class="p-4 rounded-lg bg-base-100 border border-base-300/50">
                              <p class="text-xs font-semibold text-base-content/60 mb-2">
                                <%= chunk["document_name"] %>
                              </p>
                              <div class="text-sm text-base-content/80 max-h-32 overflow-y-auto">
                                <%= String.slice(chunk["content"], 0, 200) %>...
                              </div>
                            </div>
                          <% end %>
                        </div>
                      </div>
                    </details>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>

          <!-- History & Info Sidebar -->
          <div class="space-y-6">
            <!-- Tips Card -->
            <div class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm">
              <h3 class="text-lg font-bold text-base-content mb-4 flex items-center gap-2">
                <.icon name="hero-information-circle" class="h-5 w-5 text-primary" />
                {gettext("How it works")}
              </h3>
              <ul class="space-y-3 text-sm text-base-content/70">
                <li class="flex gap-2">
                  <span class="text-primary">1.</span>
                  <span>{gettext("AI analyzes your question")}</span>
                </li>
                <li class="flex gap-2">
                  <span class="text-primary">2.</span>
                  <span>{gettext("Selects relevant topic labels")}</span>
                </li>
                <li class="flex gap-2">
                  <span class="text-primary">3.</span>
                  <span>{gettext("Searches only labeled data")}</span>
                </li>
                <li class="flex gap-2">
                  <span class="text-primary">4.</span>
                  <span>{gettext("Generates focused answer")}</span>
                </li>
              </ul>
            </div>

            <!-- Recent Queries -->
            <%= if @query_history != [] do %>
              <div class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm">
                <h3 class="text-lg font-bold text-base-content mb-4">
                  {gettext("Recent Queries")}
                </h3>
                <div class="space-y-3 max-h-96 overflow-y-auto">
                  <%= for item <- Enum.take(@query_history, 5) do %>
                    <div class="p-3 rounded-lg bg-base-200/30 border border-base-300/50">
                      <p class="text-sm font-semibold text-base-content mb-1">
                        <%= String.slice(item.question, 0, 60) %><%= if String.length(item.question) > 60,
                          do: "...",
                          else: "" %>
                      </p>
                      <div class="flex flex-wrap gap-1 mt-2">
                        <%= for label <- Enum.take(item.labels, 3) do %>
                          <span class="badge badge-xs badge-primary">
                            <%= label["name"] %>
                          </span>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </section>
    </Layouts.dashboard>
    """
  end
end
