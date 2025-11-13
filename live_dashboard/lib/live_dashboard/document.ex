defmodule LiveDashboard.Document do
  use Ecto.Schema

  schema "document" do
    field :document_name, :string, primary_key: true
    field :file_path, :string
    timestamps(type: :utc_datetime, inserted_at: :created_at, updated_at: false)
  end

  def changeset(document, attrs) do
    document
    |> Ecto.Changeset.cast(attrs, [:document_name, :file_path])
    |> Ecto.Changeset.validate_required([:document_name, :file_path])
  end
end
