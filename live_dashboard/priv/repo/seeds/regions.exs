# Seeds for regions
# Updates existing regions with slugs and codes

import Ecto.Query

alias LiveDashboard.Repo
alias LiveDashboard.Schemas.Region

# Update existing regions with slug and code
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
