defmodule LiveDashboard.Schemas.Region do
  use Ecto.Schema

  schema "regions" do
    field :name, :string

    has_many :municipalities, LiveDashboard.Schemas.Municipality
  end
end
