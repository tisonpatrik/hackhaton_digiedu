defmodule LiveDashboardWeb.LabelsLive do
  use LiveDashboardWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    # Set locale from session
    locale = Map.get(session, "locale", "en")
    Gettext.put_locale(LiveDashboardWeb.Gettext, locale)

    socket =
      socket
      |> assign(:labels, [])
      |> assign(:loading, true)
      |> assign(:error_message, nil)
      |> assign(:search_query, "")

    if connected?(socket) do
      send(self(), :load_labels)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:load_labels, socket) do
    case fetch_labels() do
      {:ok, labels} ->
        {:noreply, 
         socket 
         |> assign(:labels, labels)
         |> assign(:loading, false)}
      
      {:error, reason} ->
        {:noreply, 
         socket 
         |> assign(:error_message, reason)
         |> assign(:loading, false)}
    end
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, assign(socket, :search_query, query)}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply, assign(socket, :search_query, "")}
  end

  defp fetch_labels do
    api_url = System.get_env("DATA_PROCESSING_URL", "http://localhost:8080")

    case Req.get("#{api_url}/labels", receive_timeout: 30_000) do
      {:ok, %{status: 200, body: %{"labels" => labels}}} ->
        {:ok, labels}

      {:ok, %{status: status}} ->
        {:error, "Failed to fetch labels (status: #{status})"}

      {:error, exception} ->
        {:error, Exception.message(exception)}
    end
  end

  defp filter_labels(labels, ""), do: labels
  defp filter_labels(labels, query) do
    query_lower = String.downcase(query)
    Enum.filter(labels, fn label ->
      String.contains?(String.downcase(label["name"]), query_lower) ||
      (label["category"] && String.contains?(String.downcase(label["category"]), query_lower))
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash}>
      <section class="px-6 py-10 sm:px-10 lg:px-16 xl:px-20">
        <header class="flex flex-col gap-6 rounded-3xl bg-gradient-to-br from-primary/10 via-primary/5 to-base-100 px-8 py-10 shadow-lg">
          <div>
            <p class="text-sm font-semibold uppercase tracking-[0.35em] text-primary/70">
              {gettext("Data Management")}
            </p>
            <h1 class="mt-3 text-3xl font-extrabold tracking-tight text-base-content sm:text-4xl">
              {gettext("Labels Dashboard")}
            </h1>
            <p class="mt-4 max-w-xl text-base leading-7 text-base-content/70">
              {gettext(
                "View and manage all labels extracted from your uploaded content. Labels help categorize and search through your educational data."
              )}
            </p>
          </div>
        </header>

        <div class="mt-12">
          <!-- Search Bar -->
          <div class="mb-6">
            <form phx-submit="search" phx-change="search" class="relative">
              <input
                type="text"
                name="query"
                value={@search_query}
                placeholder={gettext("Search labels...")}
                class="input input-bordered w-full max-w-2xl"
              />
              <%= if @search_query != "" do %>
                <button
                  type="button"
                  phx-click="clear_search"
                  class="btn btn-ghost btn-sm btn-circle absolute right-2 top-2"
                >
                  <.icon name="hero-x-mark" class="h-5 w-5" />
                </button>
              <% end %>
            </form>
          </div>

          <!-- Error Message -->
          <%= if @error_message do %>
            <div class="alert alert-error mb-6">
              <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
              <span><%= @error_message %></span>
            </div>
          <% end %>

          <!-- Loading State -->
          <%= if @loading do %>
            <div class="flex justify-center py-12">
              <span class="loading loading-spinner loading-lg text-primary"></span>
            </div>
          <% else %>
            <%
              filtered_labels = filter_labels(@labels, @search_query)
              total_usage = Enum.reduce(@labels, 0, fn label, acc -> acc + label["usage_count"] end)
            %>
            
            <!-- Stats Cards -->
            <div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3 mb-8">
              <div class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm">
                <div class="flex items-center gap-4">
                  <div class="rounded-2xl bg-primary/10 p-3">
                    <.icon name="hero-tag" class="h-8 w-8 text-primary" />
                  </div>
                  <div>
                    <p class="text-3xl font-bold text-base-content"><%= length(@labels) %></p>
                    <p class="text-sm text-base-content/60">{gettext("Total Labels")}</p>
                  </div>
                </div>
              </div>

              <div class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm">
                <div class="flex items-center gap-4">
                  <div class="rounded-2xl bg-secondary/10 p-3">
                    <.icon name="hero-document-duplicate" class="h-8 w-8 text-secondary" />
                  </div>
                  <div>
                    <p class="text-3xl font-bold text-base-content"><%= total_usage %></p>
                    <p class="text-sm text-base-content/60">{gettext("Total Uses")}</p>
                  </div>
                </div>
              </div>

              <div class="rounded-3xl border border-base-300/70 bg-base-100 p-6 shadow-sm">
                <div class="flex items-center gap-4">
                  <div class="rounded-2xl bg-accent/10 p-3">
                    <.icon name="hero-funnel" class="h-8 w-8 text-accent" />
                  </div>
                  <div>
                    <p class="text-3xl font-bold text-base-content"><%= length(filtered_labels) %></p>
                    <p class="text-sm text-base-content/60">{gettext("Filtered Labels")}</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Labels Grid -->
            <%= if filtered_labels == [] do %>
              <div class="text-center py-12 rounded-3xl border border-base-300/70 bg-base-100">
                <.icon name="hero-tag" class="mx-auto h-16 w-16 text-base-content/20" />
                <p class="mt-4 text-sm text-base-content/60">
                  <%= if @search_query != "" do %>
                    {gettext("No labels match your search.")}
                  <% else %>
                    {gettext("No labels yet. Upload some files to generate labels.")}
                  <% end %>
                </p>
              </div>
            <% else %>
              <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                <%= for label <- filtered_labels do %>
                  <div class="rounded-2xl border border-base-300/70 bg-base-100 p-6 shadow-sm hover:shadow-md transition-shadow">
                    <div class="flex items-start justify-between gap-2 mb-2">
                      <div class="flex-1 min-w-0">
                        <h3 class="font-semibold text-base-content truncate" title={label["name"]}>
                          <%= label["name"] %>
                        </h3>
                        <%= if label["category"] do %>
                          <p class="text-xs text-base-content/60 mt-1">
                            <%= label["category"] %>
                          </p>
                        <% end %>
                      </div>
                      <span class="badge badge-primary badge-sm flex-shrink-0">
                        <%= label["usage_count"] %>
                      </span>
                    </div>
                    <p class="text-xs text-base-content/50 mt-2">
                      {gettext("Used in")} <%= label["usage_count"] %> <%= if label["usage_count"] == 1, do: gettext("chunk"), else: gettext("chunks") %>
                    </p>
                  </div>
                <% end %>
              </div>
            <% end %>
          <% end %>
        </div>
      </section>
    </Layouts.dashboard>
    """
  end
end
