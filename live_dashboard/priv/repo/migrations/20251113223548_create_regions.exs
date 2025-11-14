defmodule LiveDashboard.Repo.Migrations.CreateRegions do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:regions) do
      add :name, :string, null: false
    end

    create_if_not_exists index(:regions, [:name])
  end
end
