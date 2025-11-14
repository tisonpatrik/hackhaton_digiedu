defmodule LiveDashboard.Repo.Migrations.CreateGuides do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:guides) do
      add :name, :string, null: false
      add :experience, :text
      add :municipality_id, references(:municipalities, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:guides, [:municipality_id])
  end
end
