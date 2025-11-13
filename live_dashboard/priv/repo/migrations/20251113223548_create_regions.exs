defmodule LiveDashboard.Repo.Migrations.CreateRegions do
  use Ecto.Migration

  def change do
    create table(:regions) do
      add :name, :string, null: false
    end

    create index(:regions, [:name])
  end
end
