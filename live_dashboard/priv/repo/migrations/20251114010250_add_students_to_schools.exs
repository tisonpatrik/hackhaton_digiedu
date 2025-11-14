defmodule LiveDashboard.Repo.Migrations.AddStudentsToSchools do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add :students, :integer
    end
  end
end
