# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     LiveDashboard.Repo.insert!(%LiveDashboard.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias LiveDashboard.Repo
alias LiveDashboard.Schemas.Region

import Ecto.Query

regions_data = [
  %{name: "Hlavní město Praha"},
  %{name: "Středočeský kraj"},
  %{name: "Jihočeský kraj"},
  %{name: "Plzeňský kraj"},
  %{name: "Karlovarský kraj"},
  %{name: "Ústecký kraj"},
  %{name: "Liberecký kraj"},
  %{name: "Královéhradecký kraj"},
  %{name: "Pardubický kraj"},
  %{name: "Kraj Vysočina"},
  %{name: "Jihomoravský kraj"},
  %{name: "Olomoucký kraj"},
  %{name: "Zlínský kraj"},
  %{name: "Moravskoslezský kraj"}
]

if Repo.aggregate(from(r in Region), :count) == 0 do
  Repo.insert_all(Region, regions_data)
end
