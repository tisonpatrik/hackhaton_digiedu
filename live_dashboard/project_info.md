# Project Structure Overview

This document provides a quick overview of the Phoenix application structure for juniors. It will help you understand where to find things and where to look when adding new features.

## Basic Structure

### `/lib` - Main Application Code

#### `/lib/live_dashboard` - Business Logic and Data Layer
- **`application.ex`** - Application entry point, defines the supervision tree (Repo, Endpoint, PubSub, etc.)
- **`repo.ex`** - Ecto repository for database operations (queries, transactions)
- **`mailer.ex`** - Email sending configuration (Swoosh)

**When adding a new feature:**
- New data models (schemas) → `/lib/live_dashboard/` (e.g. `user.ex`, `post.ex`)
- Business logic → `/lib/live_dashboard/` (e.g. `accounts.ex`, `posts.ex`)

#### `/lib/live_dashboard_web` - Web Layer (Phoenix)

##### `/lib/live_dashboard_web/router.ex`
- **Defines all application routes**
- Pipelines (`:browser`, `:api`) - middleware for requests
- Scopes - grouping routes by functionality

**When adding a new feature:**
- New routes → add here to the appropriate scope

##### `/lib/live_dashboard_web/controllers/`
- **`page_controller.ex`** - Controller for static pages
- **`error_html.ex`** / **`error_json.ex`** - Error handling

**When adding a new feature:**
- New controller → `/lib/live_dashboard_web/controllers/` (e.g. `user_controller.ex`)
- View modules → `/lib/live_dashboard_web/controllers/user_html/` (for HTML templates)

##### `/lib/live_dashboard_web/components/`
- **`core_components.ex`** - Shared UI components (buttons, forms, inputs, etc.)
- **`layouts.ex`** - Layout wrapper for all pages
- **`layouts/root.html.heex`** - Root HTML template

**When adding a new feature:**
- New shared components → `core_components.ex`
- LiveView components → `/lib/live_dashboard_web/components/` (e.g. `user_card.ex`)

##### `/lib/live_dashboard_web/endpoint.ex`
- Phoenix endpoint configuration (URL, port, etc.)
- Middleware pipeline

##### `/lib/live_dashboard_web.ex`
- **Entry point for the web layer**
- Macros for `use LiveDashboardWeb, :controller`, `:live_view`, `:html`
- Imports common functions and components

**When adding a new feature:**
- Generally don't touch this unless you need to add global helper functions

##### `/lib/live_dashboard_web/telemetry.ex`
- Telemetry configuration (metrics, monitoring)

### `/assets` - Frontend Assets

#### `/assets/css/app.css`
- **Main CSS file**
- Tailwind CSS imports
- Custom CSS styles

**When adding a new feature:**
- Custom styles → add here or use Tailwind classes directly in templates

#### `/assets/js/app.js`
- **Main JavaScript file**
- Phoenix LiveView hooks
- Custom JavaScript logic

**When adding a new feature:**
- JavaScript logic → add here or create a new module in `/assets/js/`
- LiveView hooks → define here and use `phx-hook="HookName"` in templates

#### `/assets/vendor/`
- External JavaScript libraries (Heroicons, Topbar, DaisyUI)

### `/config` - Configuration

- **`config.exs`** - Base configuration (shared for all environments)
- **`dev.exs`** - Development configuration
- **`test.exs`** - Test configuration
- **`prod.exs`** - Production configuration
- **`runtime.exs`** - Runtime configuration (env variables)

**When adding a new feature:**
- New configuration values → add to the appropriate config file

### `/priv/repo` - Database

- **`migrations/`** - Ecto migrations (database structure)
- **`seeds.exs`** - Seed data for development/testing

**When adding a new feature:**
- New tables/columns → create migration: `mix ecto.gen.migration migration_name`
- Test data → add to `seeds.exs`

### `/test` - Tests

- **`test_helper.exs`** - Test setup
- **`live_dashboard_web/`** - Tests for web layer
- **`support/`** - Test helpers and fixtures

**When adding a new feature:**
- Tests for new functionality → create test file in the appropriate folder
- Test helpers → `/test/support/`

### `/priv/static` - Static Files

- Favicon, images, robots.txt
- These files are served directly without processing

## Typical Workflow When Adding a New Feature

### 1. Data Layer
```
/lib/live_dashboard/
  ├── user.ex              # Ecto schema
  └── accounts.ex           # Business logic (e.g. create_user/1, get_user/1)
```

### 2. Migrations
```
mix ecto.gen.migration create_users
# Edit /priv/repo/migrations/YYYYMMDDHHMMSS_create_users.exs
```

### 3. Web Layer
```
/lib/live_dashboard_web/
  ├── controllers/
  │   └── user_controller.ex        # Controller for CRUD operations
  ├── controllers/user_html/
  │   └── index.html.heex           # Templates
  └── components/
      └── user_card.ex               # LiveView component (if needed)
```

### 4. Routes
```elixir
# /lib/live_dashboard_web/router.ex
scope "/users", LiveDashboardWeb do
  pipe_through :browser
  get "/", UserController, :index
  get "/:id", UserController, :show
end
```

### 5. Tests
```
/test/live_dashboard_web/
  └── user_controller_test.exs
```

## Important Conventions

- **LiveViews** - For interactive UI with real-time updates (naming: `UserLive`, `PostLive`)
- **Controllers** - For traditional request/response cycles (naming: `UserController`)
- **Components** - Shared UI components in `core_components.ex` or standalone LiveView components
- **Templates** - HEEx files (`.html.heex`) in `controllers/module_html/`
- **Schemas** - Ecto schemas in `/lib/live_dashboard/` (naming: `User`, `Post`)

## Useful Commands

```bash
# Start server
mix phx.server

# Create migration
mix ecto.gen.migration name

# Run migrations
mix ecto.migrate

# Generate new LiveView
mix phx.gen.live Accounts User users name:string email:string

# Run tests
mix test

# Format code
mix format

# Pre-commit check
mix precommit
```

## Where to Find Help

- **Phoenix documentation**: https://hexdocs.pm/phoenix/
- **Ecto documentation**: https://hexdocs.pm/ecto/
- **LiveView documentation**: https://hexdocs.pm/phoenix_live_view/
- **Tailwind CSS**: https://tailwindcss.com/docs
