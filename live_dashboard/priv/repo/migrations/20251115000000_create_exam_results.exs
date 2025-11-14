defmodule LiveDashboard.Repo.Migrations.CreateExamResults do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:exam_results, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :school_id, references(:schools, on_delete: :restrict), null: false
      add :exam_date, :date, null: false
      add :subject, :string, null: false
      add :average_score, :decimal, precision: 5, scale: 2, null: false
      add :total_students, :integer, null: false
      add :pass_rate, :decimal, precision: 5, scale: 2, null: false

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:exam_results, [:school_id])
    create_if_not_exists index(:exam_results, [:exam_date])
    create_if_not_exists index(:exam_results, [:subject])
  end
end
