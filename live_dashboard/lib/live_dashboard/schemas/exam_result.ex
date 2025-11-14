defmodule LiveDashboard.Schemas.ExamResult do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exam_results" do
    field :exam_date, :date
    field :subject, :string
    field :average_score, :decimal
    field :total_students, :integer
    field :pass_rate, :decimal

    belongs_to :school, LiveDashboard.Schemas.School

    timestamps(type: :utc_datetime)
  end

  def changeset(exam_result, attrs) do
    exam_result
    |> cast(attrs, [:school_id, :exam_date, :subject, :average_score, :total_students, :pass_rate])
    |> validate_required([:school_id, :exam_date, :subject, :average_score, :total_students, :pass_rate])
    |> validate_number(:average_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_number(:total_students, greater_than: 0)
    |> validate_number(:pass_rate, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> foreign_key_constraint(:school_id)
  end
end
