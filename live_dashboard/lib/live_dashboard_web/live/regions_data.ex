defmodule LiveDashboardWeb.RegionsData do
  @moduledoc """
  GeoJSON data for Czech Republic regions (kraje).
  Simplified coordinates for demonstration purposes.
  """

  alias LiveDashboard.Repo
  alias LiveDashboard.Schemas.Region

  # Hard-coded coordinates for regions (simplified)
  @region_coordinates %{
    "praha" => [[14.35, 50.05], [14.55, 50.05], [14.55, 50.12], [14.35, 50.12], [14.35, 50.05]],
    "stredocesky" => [[13.8, 49.5], [15.2, 49.5], [15.2, 50.3], [13.8, 50.3], [13.8, 49.5]],
    "jihocesky" => [[13.5, 48.5], [15.0, 48.5], [15.0, 49.5], [13.5, 49.5], [13.5, 48.5]],
    "plzensky" => [[12.5, 49.0], [13.8, 49.0], [13.8, 50.0], [12.5, 50.0], [12.5, 49.0]],
    "karlovarsky" => [[12.0, 49.8], [13.0, 49.8], [13.0, 50.3], [12.0, 50.3], [12.0, 49.8]],
    "ustecky" => [[13.0, 50.0], [14.5, 50.0], [14.5, 50.8], [13.0, 50.8], [13.0, 50.0]],
    "liberecky" => [[14.5, 50.5], [15.5, 50.5], [15.5, 51.0], [14.5, 51.0], [14.5, 50.5]],
    "kralovehradecky" => [[15.0, 50.0], [16.2, 50.0], [16.2, 50.7], [15.0, 50.7], [15.0, 50.0]],
    "pardubicky" => [[15.5, 49.5], [16.5, 49.5], [16.5, 50.3], [15.5, 50.3], [15.5, 49.5]],
    "vysocina" => [[15.0, 49.0], [16.2, 49.0], [16.2, 49.8], [15.0, 49.8], [15.0, 49.0]],
    "jihomoravsky" => [[16.0, 48.5], [17.2, 48.5], [17.2, 49.5], [16.0, 49.5], [16.0, 48.5]],
    "olomoucky" => [[16.5, 49.3], [17.5, 49.3], [17.5, 50.2], [16.5, 50.2], [16.5, 49.3]],
    "zlinsky" => [[17.0, 49.0], [18.0, 49.0], [18.0, 49.8], [17.0, 49.8], [17.0, 49.0]],
    "moravskoslezsky" => [[17.5, 49.5], [18.8, 49.5], [18.8, 50.3], [17.5, 50.3], [17.5, 49.5]]
  }

  def get_regions_geojson do
    regions = Repo.all(Region)

    features =
      Enum.map(regions, fn region ->
        coordinates =
          Map.get(@region_coordinates, region.slug, [[0, 0], [0, 0], [0, 0], [0, 0], [0, 0]])

        %{
          type: "Feature",
          id: region.slug,
          properties: %{id: region.slug, name: region.name, code: region.code},
          geometry: %{
            type: "Polygon",
            coordinates: [coordinates]
          }
        }
      end)

    %{
      type: "FeatureCollection",
      features: features
    }
  end
end
