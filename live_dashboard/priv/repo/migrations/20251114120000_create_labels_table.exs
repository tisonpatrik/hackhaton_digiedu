defmodule LiveDashboard.Repo.Migrations.CreateLabelsTable do
  use Ecto.Migration

  def up do
    # Create labels table
    create table("labels", primary_key: false) do
      add :id, :serial, primary_key: true
      add :name, :string, size: 255, null: false
      add :normalized_name, :string, size: 255, null: false
      add :category, :string, size: 100
      add :usage_count, :integer, default: 0, null: false
      add :created_at, :utc_datetime, default: fragment("CURRENT_TIMESTAMP")
      add :updated_at, :utc_datetime, default: fragment("CURRENT_TIMESTAMP")
    end

    # Create unique index on normalized_name to prevent duplicates
    create unique_index("labels", [:normalized_name])
    
    # Create index on category for filtering
    create index("labels", [:category])
    
    # Create chunk_labels junction table for many-to-many relationship
    create table("chunk_labels", primary_key: false) do
      add :chunk_document_name, references("chunk", column: :document_name, type: :string, on_delete: :delete_all), null: false
      add :label_id, references("labels", column: :id, on_delete: :delete_all), null: false
      add :created_at, :utc_datetime, default: fragment("CURRENT_TIMESTAMP")
    end
    
    # Create composite primary key
    create unique_index("chunk_labels", [:chunk_document_name, :label_id])
    
    # Create index for reverse lookups (find chunks by label)
    create index("chunk_labels", [:label_id])
  end

  def down do
    drop table("chunk_labels")
    drop table("labels")
  end
end
