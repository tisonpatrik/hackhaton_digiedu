# Seeds for regions
# Creates regions if they don't exist, then updates with slugs and codes

import Ecto.Query

alias LiveDashboard.Repo
alias LiveDashboard.Schemas.Region

# First, create regions if they don't exist
regions_data = [
  %{name: "Hlavní město Praha", slug: "praha", code: "A"},
  %{name: "Středočeský kraj", slug: "stredocesky", code: "S"},
  %{name: "Jihočeský kraj", slug: "jihocesky", code: "C"},
  %{name: "Plzeňský kraj", slug: "plzensky", code: "P"},
  %{name: "Karlovarský kraj", slug: "karlovarsky", code: "K"},
  %{name: "Ústecký kraj", slug: "ustecky", code: "U"},
  %{name: "Liberecký kraj", slug: "liberecky", code: "L"},
  %{name: "Královéhradecký kraj", slug: "kralovehradecky", code: "H"},
  %{name: "Pardubický kraj", slug: "pardubicky", code: "E"},
  %{name: "Kraj Vysočina", slug: "vysocina", code: "J"},
  %{name: "Jihomoravský kraj", slug: "jihomoravsky", code: "B"},
  %{name: "Olomoucký kraj", slug: "olomoucky", code: "M"},
  %{name: "Zlínský kraj", slug: "zlinsky", code: "Z"},
  %{name: "Moravskoslezský kraj", slug: "moravskoslezsky", code: "T"}
]

# Create regions if they don't exist
for region_data <- regions_data do
  case Repo.get_by(Region, name: region_data.name) do
    nil ->
      Repo.insert!(%Region{
        name: region_data.name,
        slug: region_data.slug,
        code: region_data.code
      })
    existing ->
      # Update existing region with slug and code if missing
      changeset = Ecto.Changeset.change(existing, slug: region_data.slug, code: region_data.code)
      Repo.update!(changeset)
  end
end

# Update existing regions with slug and code (backup - in case some were created without them)
Repo.update_all(
  from(r in Region, where: r.name == "Hlavní město Praha"),
  set: [slug: "praha", code: "A"]
)

Repo.update_all(
  from(r in Region, where: r.name == "Středočeský kraj"),
  set: [slug: "stredocesky", code: "S"]
)

Repo.update_all(
  from(r in Region, where: r.name == "Jihočeský kraj"),
  set: [slug: "jihocesky", code: "C"]
)

Repo.update_all(
  from(r in Region, where: r.name == "Plzeňský kraj"),
  set: [slug: "plzensky", code: "P"]
)

Repo.update_all(
  from(r in Region, where: r.name == "Karlovarský kraj"),
  set: [slug: "karlovarsky", code: "K"]
)

Repo.update_all(
  from(r in Region, where: r.name == "Ústecký kraj"),
  set: [slug: "ustecky", code: "U"]
)

Repo.update_all(
  from(r in Region, where: r.name == "Liberecký kraj"),
  set: [slug: "liberecky", code: "L"]
)

Repo.update_all(
  from(r in Region, where: r.name == "Královéhradecký kraj"),
  set: [slug: "kralovehradecky", code: "H"]
)

Repo.update_all(
  from(r in Region, where: r.name == "Pardubický kraj"),
  set: [slug: "pardubicky", code: "E"]
)

Repo.update_all(
  from(r in Region, where: r.name == "Kraj Vysočina"),
  set: [slug: "vysocina", code: "J"]
)

Repo.update_all(
  from(r in Region, where: r.name == "Jihomoravský kraj"),
  set: [slug: "jihomoravsky", code: "B"]
)

Repo.update_all(
  from(r in Region, where: r.name == "Olomoucký kraj"),
  set: [slug: "olomoucky", code: "M"]
)

Repo.update_all(
  from(r in Region, where: r.name == "Zlínský kraj"),
  set: [slug: "zlinsky", code: "Z"]
)

Repo.update_all(
  from(r in Region, where: r.name == "Moravskoslezský kraj"),
  set: [slug: "moravskoslezsky", code: "T"]
)
