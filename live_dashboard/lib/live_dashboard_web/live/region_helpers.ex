defmodule LiveDashboardWeb.RegionHelpers do
  @moduledoc """
  Helper functions for working with regions, including slug mapping.
  """

  def region_slug(region) when is_map(region) do
    case region.name do
      "Hlavní město Praha" -> "praha"
      "Středočeský kraj" -> "stredocesky"
      "Jihočeský kraj" -> "jihocesky"
      "Plzeňský kraj" -> "plzensky"
      "Karlovarský kraj" -> "karlovarsky"
      "Ústecký kraj" -> "ustecky"
      "Liberecký kraj" -> "liberecky"
      "Královéhradecký kraj" -> "kralovehradecky"
      "Pardubický kraj" -> "pardubicky"
      "Kraj Vysočina" -> "vysocina"
      "Jihomoravský kraj" -> "jihomoravsky"
      "Olomoucký kraj" -> "olomoucky"
      "Zlínský kraj" -> "zlinsky"
      "Moravskoslezský kraj" -> "moravskoslezsky"
      _ -> Integer.to_string(region.id)
    end
  end

  def region_from_slug(slug) when is_binary(slug) do
    case slug do
      "praha" -> "Hlavní město Praha"
      "stredocesky" -> "Středočeský kraj"
      "jihocesky" -> "Jihočeský kraj"
      "plzensky" -> "Plzeňský kraj"
      "karlovarsky" -> "Karlovarský kraj"
      "ustecky" -> "Ústecký kraj"
      "liberecky" -> "Liberecký kraj"
      "kralovehradecky" -> "Královéhradecký kraj"
      "pardubicky" -> "Pardubický kraj"
      "vysocina" -> "Kraj Vysočina"
      "jihomoravsky" -> "Jihomoravský kraj"
      "olomoucky" -> "Olomoucký kraj"
      "zlinsky" -> "Zlínský kraj"
      "moravskoslezsky" -> "Moravskoslezský kraj"
      _ -> nil
    end
  end
end
