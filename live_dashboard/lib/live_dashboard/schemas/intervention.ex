defmodule LiveDashboard.Schemas.Intervention do
  use Ecto.Schema

  schema "interventions" do
    field :intervention_type, :string
    field :date, :date
    field :participant_count, :integer

    belongs_to :project, LiveDashboard.Schemas.Project
    belongs_to :school, LiveDashboard.Schemas.School
    belongs_to :guide, LiveDashboard.Schemas.Guide

    timestamps(type: :utc_datetime)
  end
end
