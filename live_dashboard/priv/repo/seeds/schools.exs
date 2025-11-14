# Seeds for schools
# Creates schools associated with municipalities

alias LiveDashboard.Repo
alias LiveDashboard.Schemas.Municipality
alias LiveDashboard.Schemas.School

# School data with municipality associations
schools_data = [
  %{
    name: "Gymnázium Jana Nerudy",
    type: "Gymnázium",
    students: 450,
    municipality_name: "Praha 1"
  },
  %{
    name: "Základní škola U Školky",
    type: "Základní škola",
    students: 320,
    municipality_name: "Praha 2"
  },
  %{
    name: "Střední škola Praha 3",
    type: "Střední škola",
    students: 400,
    municipality_name: "Praha 3"
  },
  %{name: "Gymnázium Praha 4", type: "Gymnázium", students: 350, municipality_name: "Praha 4"},
  %{
    name: "Základní škola Praha 5",
    type: "Základní škola",
    students: 280,
    municipality_name: "Praha 5"
  },
  %{
    name: "Střední průmyslová škola",
    type: "Střední škola",
    students: 280,
    municipality_name: "Kolín"
  },
  %{
    name: "Gymnázium České Budějovice",
    type: "Gymnázium",
    students: 380,
    municipality_name: "České Budějovice"
  },
  %{
    name: "Základní škola Plzeň",
    type: "Základní škola",
    students: 290,
    municipality_name: "Plzeň"
  },
  %{
    name: "Technická univerzita Liberec",
    type: "Vysoká škola",
    students: 5200,
    municipality_name: "Liberec"
  },
  %{
    name: "Gymnázium Hradec Králové",
    type: "Gymnázium",
    students: 410,
    municipality_name: "Hradec Králové"
  },
  %{
    name: "Univerzita Pardubice",
    type: "Vysoká škola",
    students: 8900,
    municipality_name: "Pardubice"
  },
  %{
    name: "Střední škola Jihlava",
    type: "Střední škola",
    students: 350,
    municipality_name: "Jihlava"
  },
  %{
    name: "Masarykova univerzita",
    type: "Vysoká škola",
    students: 32000,
    municipality_name: "Brno"
  },
  %{
    name: "Univerzita Palackého",
    type: "Vysoká škola",
    students: 21000,
    municipality_name: "Olomouc"
  },
  %{
    name: "Univerzita Tomáše Bati",
    type: "Vysoká škola",
    students: 9200,
    municipality_name: "Zlín"
  },
  %{
    name: "Ostravská univerzita",
    type: "Vysoká škola",
    students: 9800,
    municipality_name: "Ostrava"
  },
  %{
    name: "Vysoká škola báňská",
    type: "Vysoká škola",
    students: 15600,
    municipality_name: "Ostrava"
  },
  %{
    name: "Základní škola Ostrava",
    type: "Základní škola",
    students: 275,
    municipality_name: "Ostrava"
  }
]

# Create schools (skip if already exists)
for school_data <- schools_data do
  municipality = Repo.get_by(Municipality, name: school_data.municipality_name)

  if municipality do
    case Repo.get_by(School, name: school_data.name, municipality_id: municipality.id) do
      nil ->
        Repo.insert!(%School{
          name: school_data.name,
          type: school_data.type,
          students: school_data.students,
          municipality_id: municipality.id
        })

      _ ->
        :ok
    end
  end
end
