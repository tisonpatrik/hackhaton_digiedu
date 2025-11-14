defmodule LiveDashboardWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use LiveDashboardWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1"></div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <a href="https://phoenixframework.org/" class="btn btn-ghost">Website</a>
          </li>
          <li>
            <a href="https://github.com/phoenixframework/phoenix" class="btn btn-ghost">GitHub</a>
          </li>
          <li>
            <.theme_toggle />
          </li>
          <li>
            <a href="https://hexdocs.pm/phoenix/overview.html" class="btn btn-primary">
              Get Started <span aria-hidden="true">&rarr;</span>
            </a>
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Renders a full-width dashboard layout without max-width constraints.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  slot :inner_block, required: true

  def dashboard(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden bg-base-200">
      <.sidebar />

      <div class="flex flex-1 flex-col overflow-hidden">
        <header class="navbar px-4 sm:px-6 lg:px-8 bg-base-100 gap-4">
          <div class="flex-1 max-w-2xl w-full">
            <form action="/query" method="get" class="flex gap-2 items-center">
              <div class="relative flex-1">
                <input
                  type="text"
                  name="q"
                  placeholder={gettext("Search your data with AI...")}
                  class="input input-bordered w-full pl-10 text-sm"
                />
                <.icon name="hero-magnifying-glass" class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-base-content/40 pointer-events-none" />
              </div>
              <button type="submit" class="btn btn-sm btn-primary gap-1.5 flex-shrink-0 whitespace-nowrap">
                <.icon name="hero-sparkles" class="h-4 w-4" />
                {gettext("Ask AI")}
              </button>
            </form>
          </div>
          <div class="flex items-center gap-4 ml-auto">
            <ul class="flex flex-column px-1 space-x-4 items-center">
              <li>
                <.locale_toggle />
              </li>
              <li>
                <.theme_toggle />
              </li>
            </ul>
          </div>
        </header>

        <main class="flex-1 overflow-y-auto">
          {render_slot(@inner_block)}
        </main>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Renders a collapsible sidebar menu with expandable sections.
  """
  attr :catalog_menu_items, :list, default: nil

  def sidebar(assigns) do
    catalog_items = assigns[:catalog_menu_items] || LiveDashboardWeb.MenuHelpers.catalog_menu_items()

    assigns = assign(assigns, :catalog_items, catalog_items)

    ~H"""
    <aside class="w-64 bg-base-100 border-r border-base-300 flex flex-col">
      <div class="p-4 border-b border-base-300">
        <h2 class="text-lg font-bold text-base-content">{gettext("Menu")}</h2>
      </div>

      <nav class="flex-1 overflow-y-auto p-4 space-y-2">
        <.link navigate={~p"/"} class="menu-section-header">
          <.icon name="hero-chart-bar" class="w-5 h-5" />
          <span class="flex-1 text-left font-semibold">{gettext("Overview")}</span>
        </.link>

        <.menu_section title={gettext("Catalog")} icon="hero-building-library">
          <:item :for={item <- @catalog_items}>
            <.link navigate={item.route} class="menu-item">
              <.icon name={item.icon} class="w-5 h-5" />
              <span>
                {Gettext.gettext(LiveDashboardWeb.Gettext, item.label)}
                <%= if Map.has_key?(item, :count) do %>
                  <span class="ml-2 text-xs text-base-content/50">({item.count})</span>
                <% end %>
              </span>
            </.link>
          </:item>
        </.menu_section>

        <.menu_section title={gettext("Data Processing")} icon="hero-cpu-chip">
          <:item>
            <.link navigate={~p"/upload"} class="menu-item">
              <.icon name="hero-cloud-arrow-up" class="w-5 h-5" />
              <span>{gettext("File Upload")}</span>
            </.link>
          </:item>
          <:item>
            <.link navigate={~p"/labels"} class="menu-item">
              <.icon name="hero-tag" class="w-5 h-5" />
              <span>{gettext("Labels Dashboard")}</span>
            </.link>
          </:item>
          <:item>
            <.link navigate={~p"/query"} class="menu-item">
              <.icon name="hero-sparkles" class="w-5 h-5" />
              <span>{gettext("Ask Questions")}</span>
            </.link>
          </:item>
          <:item>
            <a href="#" class="menu-item">
              <.icon name="hero-document-text" class="w-5 h-5" />
              <span>{gettext("Transcriptions")}</span>
            </a>
          </:item>
        </.menu_section>

        <.menu_section title={gettext("Analytics")} icon="hero-chart-bar-square">
          <:item>
            <.link navigate={~p"/regions"} class="menu-item">
              <.icon name="hero-map" class="w-5 h-5" />
              <span>{gettext("Regions")}</span>
            </.link>
          </:item>
          <:item>
            <a href="#" class="menu-item">
              <.icon name="hero-academic-cap" class="w-5 h-5" />
              <span>{gettext("Courses")}</span>
            </a>
          </:item>
        </.menu_section>

        <.menu_section title={gettext("Settings")} icon="hero-cog-6-tooth">
          <:item>
            <a href="#" class="menu-item">
              <.icon name="hero-wrench-screwdriver" class="w-5 h-5" />
              <span>{gettext("Configuration")}</span>
            </a>
          </:item>
          <:item>
            <a href="#" class="menu-item">
              <.icon name="hero-shield-check" class="w-5 h-5" />
              <span>{gettext("Security")}</span>
            </a>
          </:item>
        </.menu_section>
      </nav>
    </aside>
    """
  end

  @doc """
  Renders a collapsible menu section.
  """
  attr :title, :string, required: true
  attr :icon, :string, required: true
  attr :default_open, :boolean, default: false
  slot :item, required: true

  def menu_section(assigns) do
    section_id = "menu-section-#{String.replace(assigns.title, " ", "-") |> String.downcase()}"
    chevron_id = "#{section_id}-chevron"
    open_class = if assigns.default_open, do: "", else: "hidden"

    assigns =
      assigns
      |> assign(:section_id, section_id)
      |> assign(:chevron_id, chevron_id)
      |> assign(:open_class, open_class)

    ~H"""
    <div class="menu-section">
      <button
        type="button"
        class="menu-section-header"
        phx-click={
          JS.toggle(
            to: "##{@section_id}",
            in:
              {"transition-all duration-300 ease-in-out", "opacity-0 max-h-0", "opacity-100 max-h-96"},
            out:
              {"transition-all duration-300 ease-in-out", "opacity-100 max-h-96", "opacity-0 max-h-0"}
          )
          |> JS.toggle_class("rotate-180", to: "##{@chevron_id}")
        }
      >
        <.icon name={@icon} class="w-5 h-5" />
        <span class="flex-1 text-left font-semibold">{@title}</span>
        <span id={@chevron_id} class={if(assigns.default_open, do: "rotate-180", else: "")}>
          <.icon name="hero-chevron-down" class="w-4 h-4 transition-transform duration-200" />
        </span>
      </button>

      <div id={@section_id} class={["menu-section-content", @open_class]}>
        <div class="pl-7 space-y-1 pt-2">
          <%= for item <- @item do %>
            {render_slot(item)}
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides language toggle between Czech and English.
  """
  def locale_toggle(assigns) do
    current_locale = Gettext.get_locale(LiveDashboardWeb.Gettext)
    left_position = if current_locale == "cs", do: "left-1/2", else: "left-0"

    assigns = assign(assigns, :left_position, left_position)

    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class={[
        "absolute w-1/2 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 transition-[left]",
        @left_position
      ]} />

      <button
        phx-click="set-locale"
        phx-value-locale="en"
        class="relative z-10 flex p-2 cursor-pointer w-1/2 items-center justify-center"
      >
        <span class="text-xs font-semibold text-white">EN</span>
      </button>

      <button
        phx-click="set-locale"
        phx-value-locale="cs"
        class="relative z-10 flex p-2 cursor-pointer w-1/2 items-center justify-center"
      >
        <span class="text-xs font-semibold text-white">CS</span>
      </button>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=latte]_&]:left-1/3 [[data-theme=mocha]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="latte"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="mocha"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
