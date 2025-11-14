defmodule LiveDashboard.Repo.Migrations.CreateFileJobsTable do
  use Ecto.Migration

  def change do
    create table(:file_jobs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :filename, :string, null: false
      add :file_type, :string, null: false
      add :file_size, :bigint, null: false
      add :status, :string, null: false, default: "pending"
      add :progress, :integer, default: 0
      add :result_path, :string
      add :transcript_text, :text
      add :error_message, :text
      
      timestamps(type: :utc_datetime)
    end

    create index(:file_jobs, [:status])
    create index(:file_jobs, [:inserted_at])
  end
end
