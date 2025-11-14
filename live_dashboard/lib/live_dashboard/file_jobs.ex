defmodule LiveDashboard.FileJobs do
  @moduledoc """
  Context for managing file processing jobs.
  """
  
  import Ecto.Query
  alias LiveDashboard.Repo
  alias LiveDashboard.FileJobs.Job

  @doc """
  Creates a new file processing job.
  """
  def create_job(attrs) do
    %Job{}
    |> Job.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a job by ID.
  """
  def get_job(id) do
    Repo.get(Job, id)
  end

  @doc """
  Lists all jobs, ordered by most recent first.
  """
  def list_jobs(limit \\ 50) do
    Job
    |> order_by([j], desc: j.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Lists jobs by status.
  """
  def list_jobs_by_status(status) do
    Job
    |> where([j], j.status == ^status)
    |> order_by([j], desc: j.inserted_at)
    |> Repo.all()
  end

  @doc """
  Updates a job.
  """
  def update_job(%Job{} = job, attrs) do
    job
    |> Job.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates job status.
  """
  def update_job_status(job_id, status, attrs \\ %{}) do
    case get_job(job_id) do
      nil -> {:error, :not_found}
      job ->
        attrs = Map.put(attrs, :status, status)
        update_job(job, attrs)
    end
  end

  @doc """
  Subscribes to job updates for real-time notifications.
  """
  def subscribe do
    Phoenix.PubSub.subscribe(LiveDashboard.PubSub, "file_jobs")
  end

  @doc """
  Broadcasts job update to subscribers.
  """
  def broadcast_job_update(job) do
    Phoenix.PubSub.broadcast(LiveDashboard.PubSub, "file_jobs", {:job_updated, job})
  end
end
