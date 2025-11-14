defmodule LiveDashboard.Repo.Migrations.CreateChunkTable do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS vector"

    create table("chunk", primary_key: false) do
      add :document_name, :string, size: 1024, null: false, primary_key: true
      add :content, :text, null: false
      add :embedding, :"vector(1024)"
      add :created_at, :utc_datetime, default: fragment("CURRENT_TIMESTAMP")
    end
  end

  def down do
    drop table("chunk")
    execute "DROP EXTENSION IF EXISTS vector"
  end
end
