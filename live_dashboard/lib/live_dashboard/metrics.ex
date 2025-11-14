defmodule LiveDashboard.Metrics do
  alias LiveDashboard.Repo
  alias LiveDashboard.Schemas.School

  def get_active_learners_count do
    # Count students from all schools
    Repo.aggregate(School, :sum, :students) || 0
  end

  def get_completion_rate do
    # Calculate based on interventions or mock for now
    # This would need actual completion tracking data
    # Placeholder - implement based on your data model
    78.5
  end

  def get_avg_session_length do
    # Calculate from intervention data or telemetry
    # Placeholder implementation
    # minutes
    38
  end

  def get_engagement_score do
    # Composite metric from various factors
    # Placeholder - calculate from real data
    8.2
  end

  def get_recent_activity do
    # Get recent interventions, school additions, etc.
    # This would query recent database changes
    [
      %{type: :intervention, description: "New intervention added", time: "2 hours ago"},
      %{type: :school, description: "School profile updated", time: "4 hours ago"}
      # ... more items
    ]
  end
end
