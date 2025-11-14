defmodule LiveDashboard.Schemas.Region do
  use Ecto.Schema

  schema "regions" do
    field :slug, :string
    field :code, :string
    field :name, :string

    has_many :municipalities, LiveDashboard.Schemas.Municipality
  end
end
