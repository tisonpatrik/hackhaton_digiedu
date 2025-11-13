defmodule LiveDashboard.Schemas.Municipality do
  use Ecto.Schema

  schema "municipalities" do
    field :name, :string

    belongs_to :region, LiveDashboard.Schemas.Region
    has_many :schools, LiveDashboard.Schemas.School
    has_many :guides, LiveDashboard.Schemas.Guide
    has_many :projects, LiveDashboard.Schemas.Project

    timestamps(type: :utc_datetime)
  end
end
