# Seeds for municipalities
# Creates municipalities associated with regions

alias LiveDashboard.Repo
alias LiveDashboard.Schemas.Region
alias LiveDashboard.Schemas.Municipality

# Municipality data with region associations
municipalities_data = [
  # Praha region
  %{name: "Praha 1", region_slug: "praha"},
  %{name: "Praha 2", region_slug: "praha"},
  %{name: "Praha 3", region_slug: "praha"},
  %{name: "Praha 4", region_slug: "praha"},
  %{name: "Praha 5", region_slug: "praha"},
  # Other regions
  %{name: "Kolín", region_slug: "stredocesky"},
  %{name: "České Budějovice", region_slug: "jihocesky"},
  %{name: "Plzeň", region_slug: "plzensky"},
  %{name: "Liberec", region_slug: "liberecky"},
  %{name: "Hradec Králové", region_slug: "kralovehradecky"},
  %{name: "Pardubice", region_slug: "pardubicky"},
  %{name: "Jihlava", region_slug: "vysocina"},
  %{name: "Brno", region_slug: "jihomoravsky"},
  %{name: "Olomouc", region_slug: "olomoucky"},
  %{name: "Zlín", region_slug: "zlinsky"},
  %{name: "Ostrava", region_slug: "moravskoslezsky"}
]

# Create municipalities (skip if already exists)
for municipality_data <- municipalities_data do
  region = Repo.get_by(Region, slug: municipality_data.region_slug)

  if region do
    case Repo.get_by(Municipality, name: municipality_data.name, region_id: region.id) do
      nil -> Repo.insert!(%Municipality{name: municipality_data.name, region_id: region.id})
      _ -> :ok
    end
  end
end
