defmodule LiveDashboard.FileJobs.Job do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "file_jobs" do
    field :filename, :string
    field :file_type, :string
    field :file_size, :integer
    field :status, :string, default: "pending"
    field :progress, :integer, default: 0  # Used for stage now, not percentage
    field :result_path, :string
    field :transcript_text, :string
    field :error_message, :string

    timestamps(type: :utc_datetime)
  end

  # Progress stages: 0=uploaded, 1=preparing, 2=transcribing, 3=finalizing
  def stage_name(0), do: "Uploaded"
  def stage_name(1), do: "Preparing audio"
  def stage_name(2), do: "Transcribing"
  def stage_name(3), do: "Finalizing"
  def stage_name(_), do: "Processing"

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [
      :filename,
      :file_type,
      :file_size,
      :status,
      :progress,
      :result_path,
      :transcript_text,
      :error_message
    ])
    |> validate_required([:filename, :file_type, :file_size])
    |> validate_inclusion(:status, ["pending", "processing", "completed", "failed"])
    |> validate_number(:progress, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  end
end
