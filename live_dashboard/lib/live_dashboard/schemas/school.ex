defmodule LiveDashboard.Schemas.School do
  use Ecto.Schema

  schema "schools" do
    field :name, :string
    field :type, :string
    field :founder, :string

    belongs_to :municipality, LiveDashboard.Schemas.Municipality
    has_many :interventions, LiveDashboard.Schemas.Intervention
    many_to_many :projects, LiveDashboard.Schemas.Project, join_through: "project_schools"

    timestamps(type: :utc_datetime)
  end
end
