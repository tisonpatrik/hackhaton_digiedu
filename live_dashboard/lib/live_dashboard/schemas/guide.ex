defmodule LiveDashboard.Schemas.Guide do
  use Ecto.Schema

  schema "guides" do
    field :name, :string
    field :experience, :string

    belongs_to :municipality, LiveDashboard.Schemas.Municipality
    has_many :interventions, LiveDashboard.Schemas.Intervention
    many_to_many :projects, LiveDashboard.Schemas.Project, join_through: "project_guides"

    timestamps(type: :utc_datetime)
  end
end
