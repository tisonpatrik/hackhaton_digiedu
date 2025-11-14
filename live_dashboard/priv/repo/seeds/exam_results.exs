# Seeds for exam results
# Creates exam results for schools across different regions and dates

alias LiveDashboard.Repo
alias LiveDashboard.Schemas.ExamResult
alias LiveDashboard.Schemas.School

# Get all schools
schools = Repo.all(School)

if Enum.empty?(schools) do
  IO.puts("⚠️  No schools found. Please seed schools first.")
else
  # Generate exam results for the last 7 months
  today = Date.utc_today()
  exam_dates = Enum.map(6..0//-1, fn months_ago ->
    Date.add(today, -months_ago * 30)
  end)

  subjects = ["Mathematics", "Czech Language", "English", "Science", "History"]

  IO.puts("Creating exam results for #{length(schools)} schools...")

  exam_results_count =
    schools
    |> Enum.reduce(0, fn school, acc ->
      school_count =
        exam_dates
        |> Enum.reduce(0, fn exam_date, date_acc ->
          date_count =
            subjects
            |> Enum.reduce(0, fn subject, subject_acc ->
              # Generate realistic exam scores (60-95 average)
              base_score = 70 + :rand.uniform(25)
              variation = :rand.uniform(10) - 5
              average_score = max(0, min(100, base_score + variation))

              # Generate total students (based on school size or random)
              total_students =
                if school.students do
                  # Use a portion of school students for each exam
                  div(school.students, length(subjects)) + :rand.uniform(20) - 10
                else
                  30 + :rand.uniform(40)
                end
              total_students = max(10, total_students)

              # Pass rate is typically correlated with average score
              pass_rate = average_score + (:rand.uniform(10) - 5)
              pass_rate = max(0, min(100, pass_rate))

              attrs = %{
                school_id: school.id,
                exam_date: exam_date,
                subject: subject,
                average_score: Decimal.new("#{average_score}"),
                total_students: total_students,
                pass_rate: Decimal.new("#{pass_rate}")
              }

              case Repo.insert(ExamResult.changeset(%ExamResult{}, attrs)) do
                {:ok, _} ->
                  subject_acc + 1
                {:error, changeset} ->
                  IO.puts("Error creating exam result: #{inspect(changeset.errors)}")
                  subject_acc
              end
            end)

          date_acc + date_count
        end)

      acc + school_count
    end)

  IO.puts("✓ Created #{exam_results_count} exam results")
end
