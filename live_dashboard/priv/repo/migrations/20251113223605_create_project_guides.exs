defmodule LiveDashboard.Repo.Migrations.CreateProjectGuides do
  use Ecto.Migration

  def change do
    create table(:project_guides) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :guide_id, references(:guides, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:project_guides, [:project_id, :guide_id])
    create index(:project_guides, [:project_id])
    create index(:project_guides, [:guide_id])
  end
end
