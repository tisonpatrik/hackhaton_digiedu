defmodule LiveDashboard.School do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schools" do
    field :name, :string
    field :region_id, :string
    field :type, :string
    field :students, :integer
    field :address, :string
    field :phone, :string
    field :email, :string
    field :website, :string
    field :description, :string
    timestamps()
  end

  def changeset(school, attrs) do
    school
    |> cast(attrs, [
      :name,
      :region_id,
      :type,
      :students,
      :address,
      :phone,
      :email,
      :website,
      :description
    ])
    |> validate_required([:name, :region_id, :type])
    |> validate_number(:students, greater_than_or_equal_to: 0)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
  end
end
