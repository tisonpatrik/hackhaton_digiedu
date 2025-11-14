defmodule LiveDashboard.Repo.Migrations.CreateMunicipalities do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:municipalities) do
      add :name, :string, null: false
      add :region_id, references(:regions, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:municipalities, [:name])
    create_if_not_exists index(:municipalities, [:region_id])
  end
end
