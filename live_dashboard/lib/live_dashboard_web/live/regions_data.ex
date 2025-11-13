defmodule LiveDashboardWeb.RegionsData do
  @moduledoc """
  GeoJSON data for Czech Republic regions (kraje).
  Simplified coordinates for demonstration purposes.
  """

  def get_regions_geojson do
    %{
      type: "FeatureCollection",
      features: [
        %{
          type: "Feature",
          id: "praha",
          properties: %{id: "praha", name: "Praha", code: "A"},
          geometry: %{
            type: "Polygon",
            coordinates: [
              [
                [14.35, 50.05],
                [14.55, 50.05],
                [14.55, 50.12],
                [14.35, 50.12],
                [14.35, 50.05]
              ]
            ]
          }
        },
        %{
          type: "Feature",
          id: "stredocesky",
          properties: %{id: "stredocesky", name: "Středočeský", code: "S"},
          geometry: %{
            type: "Polygon",
            coordinates: [
              [
                [13.8, 49.5],
                [15.2, 49.5],
                [15.2, 50.3],
                [13.8, 50.3],
                [13.8, 49.5]
              ]
            ]
          }
        },
        %{
          type: "Feature",
          id: "jihocesky",
          properties: %{id: "jihocesky", name: "Jihočeský", code: "C"},
          geometry: %{
            type: "Polygon",
            coordinates: [
              [
                [13.5, 48.5],
                [15.0, 48.5],
                [15.0, 49.5],
                [13.5, 49.5],
                [13.5, 48.5]
              ]
            ]
          }
        },
        %{
          type: "Feature",
          id: "plzensky",
          properties: %{id: "plzensky", name: "Plzeňský", code: "P"},
          geometry: %{
            type: "Polygon",
            coordinates: [
              [
                [12.5, 49.0],
                [13.8, 49.0],
                [13.8, 50.0],
                [12.5, 50.0],
                [12.5, 49.0]
              ]
            ]
          }
        },
        %{
          type: "Feature",
          id: "karlovarsky",
          properties: %{id: "karlovarsky", name: "Karlovarský", code: "K"},
          geometry: %{
            type: "Polygon",
            coordinates: [
              [
                [12.0, 49.8],
                [13.0, 49.8],
                [13.0, 50.3],
                [12.0, 50.3],
                [12.0, 49.8]
              ]
            ]
          }
        },
        %{
          type: "Feature",
          id: "ustecky",
          properties: %{id: "ustecky", name: "Ústecký", code: "U"},
          geometry: %{
            type: "Polygon",
            coordinates: [
              [
                [13.0, 50.0],
                [14.5, 50.0],
                [14.5, 50.8],
                [13.0, 50.8],
                [13.0, 50.0]
              ]
            ]
          }
        },
        %{
          type: "Feature",
          id: "liberecky",
          properties: %{id: "liberecky", name: "Liberecký", code: "L"},
          geometry: %{
            type: "Polygon",
            coordinates: [
              [
                [14.5, 50.5],
                [15.5, 50.5],
                [15.5, 51.0],
                [14.5, 51.0],
                [14.5, 50.5]
              ]
            ]
          }
        },
        %{
          type: "Feature",
          id: "kralovehradecky",
          properties: %{id: "kralovehradecky", name: "Královéhradecký", code: "H"},
          geometry: %{
            type: "Polygon",
            coordinates: [
              [
                [15.0, 50.0],
                [16.2, 50.0],
                [16.2, 50.7],
                [15.0, 50.7],
                [15.0, 50.0]
              ]
            ]
          }
        },
        %{
          type: "Feature",
          id: "pardubicky",
          properties: %{id: "pardubicky", name: "Pardubický", code: "E"},
          geometry: %{
            type: "Polygon",
            coordinates: [
              [
                [15.5, 49.5],
                [16.5, 49.5],
                [16.5, 50.3],
                [15.5, 50.3],
                [15.5, 49.5]
              ]
            ]
          }
        },
        %{
          type: "Feature",
          id: "vysocina",
          properties: %{id: "vysocina", name: "Vysočina", code: "J"},
          geometry: %{
            type: "Polygon",
            coordinates: [
              [
                [15.0, 49.0],
                [16.2, 49.0],
                [16.2, 49.8],
                [15.0, 49.8],
                [15.0, 49.0]
              ]
            ]
          }
        },
        %{
          type: "Feature",
          id: "jihomoravsky",
          properties: %{id: "jihomoravsky", name: "Jihomoravský", code: "B"},
          geometry: %{
            type: "Polygon",
            coordinates: [
              [
                [16.0, 48.5],
                [17.2, 48.5],
                [17.2, 49.5],
                [16.0, 49.5],
                [16.0, 48.5]
              ]
            ]
          }
        },
        %{
          type: "Feature",
          id: "olomoucky",
          properties: %{id: "olomoucky", name: "Olomoucký", code: "M"},
          geometry: %{
            type: "Polygon",
            coordinates: [
              [
                [16.5, 49.3],
                [17.5, 49.3],
                [17.5, 50.2],
                [16.5, 50.2],
                [16.5, 49.3]
              ]
            ]
          }
        },
        %{
          type: "Feature",
          id: "zlinsky",
          properties: %{id: "zlinsky", name: "Zlínský", code: "Z"},
          geometry: %{
            type: "Polygon",
            coordinates: [
              [
                [17.0, 49.0],
                [18.0, 49.0],
                [18.0, 49.8],
                [17.0, 49.8],
                [17.0, 49.0]
              ]
            ]
          }
        },
        %{
          type: "Feature",
          id: "moravskoslezsky",
          properties: %{id: "moravskoslezsky", name: "Moravskoslezský", code: "T"},
          geometry: %{
            type: "Polygon",
            coordinates: [
              [
                [17.5, 49.5],
                [18.8, 49.5],
                [18.8, 50.3],
                [17.5, 50.3],
                [17.5, 49.5]
              ]
            ]
          }
        }
      ]
    }
  end
end
