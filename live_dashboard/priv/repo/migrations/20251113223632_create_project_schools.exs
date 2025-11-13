defmodule LiveDashboard.Repo.Migrations.CreateProjectSchools do
  use Ecto.Migration

  def change do
    create table(:project_schools) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :school_id, references(:schools, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:project_schools, [:project_id, :school_id])
    create index(:project_schools, [:project_id])
    create index(:project_schools, [:school_id])
  end
end
