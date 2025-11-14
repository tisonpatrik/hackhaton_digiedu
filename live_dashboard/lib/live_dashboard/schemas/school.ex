defmodule LiveDashboard.Schemas.School do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schools" do
    field :name, :string
    field :type, :string
    field :founder, :string

    belongs_to :municipality, LiveDashboard.Schemas.Municipality
    has_many :interventions, LiveDashboard.Schemas.Intervention
    many_to_many :projects, LiveDashboard.Schemas.Project, join_through: "project_schools"

    timestamps(type: :utc_datetime)
  end

  def changeset(school, attrs) do
    school
    |> cast(attrs, [:name, :type, :founder, :municipality_id])
    |> validate_required([:name, :type, :municipality_id])
    |> foreign_key_constraint(:municipality_id)
  end
end
