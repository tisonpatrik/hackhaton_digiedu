defmodule LiveDashboard.Repo.Migrations.CreateInterventions do
  use Ecto.Migration

  def change do
    create table(:interventions) do
      add :intervention_type, :string, null: false
      add :date, :date, null: false
      add :project_id, references(:projects, on_delete: :restrict), null: false
      add :school_id, references(:schools, on_delete: :restrict), null: false
      add :guide_id, references(:guides, on_delete: :restrict), null: false
      add :participant_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:interventions, [:project_id])
    create index(:interventions, [:school_id])
    create index(:interventions, [:guide_id])
    create index(:interventions, [:date])
    create index(:interventions, [:intervention_type])
  end
end
