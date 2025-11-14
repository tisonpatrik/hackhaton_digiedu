defmodule LiveDashboard.Schemas.School do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schools" do
    field :name, :string
    field :type, :string
    field :founder, :string
    field :students, :integer

    belongs_to :municipality, LiveDashboard.Schemas.Municipality
    has_many :interventions, LiveDashboard.Schemas.Intervention
    many_to_many :projects, LiveDashboard.Schemas.Project, join_through: "project_schools"

    timestamps(type: :utc_datetime)
  end

  def changeset(school, attrs) do
    school
    |> cast(attrs, [:name, :type, :founder, :students, :municipality_id])
    |> validate_required([:name, :type, :municipality_id])
    |> validate_inclusion(:type, ["Základní škola", "Střední škola", "Gymnázium", "Vysoká škola"])
    |> validate_number(:students,
      greater_than: 0,
      message: "must be greater than 0",
      allow_nil: true
    )
    |> foreign_key_constraint(:municipality_id)
    |> foreign_key_constraint(:school_id, name: "interventions_school_id_fkey")
  end
end
