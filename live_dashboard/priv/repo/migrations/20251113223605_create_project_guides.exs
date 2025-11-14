defmodule LiveDashboard.Repo.Migrations.CreateProjectGuides do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:project_guides) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :guide_id, references(:guides, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists unique_index(:project_guides, [:project_id, :guide_id])
    create_if_not_exists index(:project_guides, [:project_id])
    create_if_not_exists index(:project_guides, [:guide_id])
  end
end
