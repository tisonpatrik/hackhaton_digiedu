defmodule LiveDashboard.Repo.Migrations.CreateSchools do
  use Ecto.Migration

  def change do
    create table(:schools) do
      add :name, :string, null: false
      add :type, :string, null: false
      add :municipality_id, references(:municipalities, on_delete: :restrict), null: false
      add :founder, :string

      timestamps(type: :utc_datetime)
    end

    create index(:schools, [:municipality_id])
  end
end
