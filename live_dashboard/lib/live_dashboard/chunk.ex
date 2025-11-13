defmodule LiveDashboard.Chunk do
  use Ecto.Schema

  schema "chunk" do
    field :document_name, :string, primary_key: true
    field :content, :string
    field :embedding, Pgvector.Ecto.Vector
    field :labels, {:array, :integer}
    timestamps(type: :utc_datetime, inserted_at: :created_at, updated_at: false)
  end

  def changeset(chunk, attrs) do
    chunk
    |> Ecto.Changeset.cast(attrs, [:document_name, :content, :embedding, :labels])
    |> Ecto.Changeset.validate_required([:document_name, :content])
  end
end
