defmodule LiveDashboard.Repo.Migrations.AddSlugAndCodeToRegions do
  use Ecto.Migration

  def change do
    alter table(:regions) do
      add :slug, :string
      add :code, :string
    end

    create unique_index(:regions, [:slug])
  end
end
