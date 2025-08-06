# Cleanup script for old video tasks and jobs

import Ecto.Query

IO.puts("🧹 Cleaning up old video tasks and jobs...")

# Delete old video tasks that are queued or processing
video_tasks_deleted = RaBackend.Repo.delete_all(
  from t in RaBackend.Tasks.Task,
  where: t.task_type == :video_gen and t.status in [:queued, :processing]
)

IO.puts("Deleted #{video_tasks_deleted} old video tasks")

# Delete old Oban jobs for video generation
video_jobs_deleted = RaBackend.Repo.delete_all(
  from j in Oban.Job,
  where: j.queue == "video_generation" and j.state in ["available", "executing"]
)

IO.puts("Deleted #{video_jobs_deleted} old video generation jobs")

IO.puts("✅ Cleanup complete!")
