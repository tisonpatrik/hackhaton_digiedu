defmodule LiveDashboard.Schemas.Project do
  use Ecto.Schema

  schema "projects" do
    field :name, :string
    field :type, :string
    field :start_date, :date
    field :end_date, :date
    field :goals, :string
    field :budget, :decimal

    belongs_to :municipality, LiveDashboard.Schemas.Municipality
    has_many :interventions, LiveDashboard.Schemas.Intervention
    many_to_many :schools, LiveDashboard.Schemas.School, join_through: "project_schools"
    many_to_many :guides, LiveDashboard.Schemas.Guide, join_through: "project_guides"

    timestamps(type: :utc_datetime)
  end
end
