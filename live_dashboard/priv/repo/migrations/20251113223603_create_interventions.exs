defmodule LiveDashboard.Repo.Migrations.CreateInterventions do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:interventions) do
      add :intervention_type, :string, null: false
      add :date, :date, null: false
      add :project_id, references(:projects, on_delete: :restrict), null: false
      add :school_id, references(:schools, on_delete: :restrict), null: false
      add :guide_id, references(:guides, on_delete: :restrict), null: false
      add :participant_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:interventions, [:project_id])
    create_if_not_exists index(:interventions, [:school_id])
    create_if_not_exists index(:interventions, [:guide_id])
    create_if_not_exists index(:interventions, [:date])
    create_if_not_exists index(:interventions, [:intervention_type])
  end
end
