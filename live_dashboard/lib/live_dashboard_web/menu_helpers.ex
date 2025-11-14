defmodule LiveDashboardWeb.MenuHelpers do
  @moduledoc """
  Helper functions for building dynamic menu structures.
  """
  use LiveDashboardWeb, :html

  alias LiveDashboard.Repo
  alias LiveDashboard.Schemas.Region
  alias LiveDashboard.Schemas.School

  def catalog_menu_items do
    regions_count = Repo.aggregate(Region, :count, :id)
    schools_count = Repo.aggregate(School, :count, :id)

    [
      %{
        label: "Regions",
        route: ~p"/catalog/regions",
        icon: "hero-map",
        count: regions_count
      },
      %{
        label: "All Schools",
        route: ~p"/schools",
        icon: "hero-building-library",
        count: schools_count
      },
      %{
        label: "Add School",
        route: ~p"/schools/new",
        icon: "hero-plus"
      }
    ]
  end
end
