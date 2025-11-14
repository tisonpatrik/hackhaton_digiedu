defmodule LiveDashboard.Repo.Migrations.CreateProjectSchools do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:project_schools) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :school_id, references(:schools, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists unique_index(:project_schools, [:project_id, :school_id])
    create_if_not_exists index(:project_schools, [:project_id])
    create_if_not_exists index(:project_schools, [:school_id])
  end
end
