defmodule LiveDashboard.Repo.Migrations.CreateDocumentTable do
  use Ecto.Migration

  def change do
    create table("document", primary_key: false) do
      add :document_name, :string, size: 1024, null: false, primary_key: true
      add :content, :text, null: false
      add :document_date, :date, null: false, primary_key: true
      add :created_at, :utc_datetime, default: fragment("CURRENT_TIMESTAMP")
    end
  end
end
