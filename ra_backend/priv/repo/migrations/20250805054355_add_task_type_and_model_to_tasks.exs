defmodule RaBackend.Repo.Migrations.AddTaskTypeAndModelToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :task_type, :string, default: "text_gen", null: false
      add :model, :string
      add :result_data, :map, default: %{}
    end

    # Create index for task_type for better query performance
    create index(:tasks, [:task_type])
  end
end
