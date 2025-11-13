defmodule LiveDashboard.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string, null: false
      add :region_id, references(:regions, on_delete: :restrict), null: false
      add :type, :string, null: false
      add :start_date, :date, null: false
      add :end_date, :date
      add :goals, :text
      add :budget, :decimal, precision: 12, scale: 2

      timestamps(type: :utc_datetime)
    end

    create index(:projects, [:region_id])
    create index(:projects, [:type])
    create index(:projects, [:start_date])
  end
end
