defmodule RaBackend.Repo.Migrations.AddVideoGenTaskType do
  use Ecto.Migration

  def up do
    # Add constraint for task_type enum values including video_gen
    execute """
    ALTER TABLE tasks ADD CONSTRAINT tasks_task_type_check
    CHECK (task_type = ANY(ARRAY['text_gen'::text, 'image_gen'::text, 'video_gen'::text]))
    """
  end

  def down do
    # Remove the constraint
    execute "ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_task_type_check"
  end
end
