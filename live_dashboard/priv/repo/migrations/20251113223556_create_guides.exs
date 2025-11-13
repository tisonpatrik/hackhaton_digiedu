defmodule LiveDashboard.Repo.Migrations.CreateGuides do
  use Ecto.Migration

  def change do
    create table(:guides) do
      add :name, :string, null: false
      add :experience, :text
      add :region_id, references(:regions, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:guides, [:region_id])
  end
end
