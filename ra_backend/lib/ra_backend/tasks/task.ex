defmodule RaBackend.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tasks" do
    field :user_id, :binary_id
    field :status, Ecto.Enum, values: [:queued, :processing, :completed, :failed], default: :queued
    field :progress, :float, default: 0.0
    field :input_data, :map, default: %{}
    field :task_type, Ecto.Enum, values: [:text_gen, :image_gen], default: :text_gen
    field :model, :string
    field :result_data, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:user_id, :status, :progress, :input_data, :task_type, :model, :result_data])
    |> validate_required([:user_id, :status, :task_type])
    |> validate_inclusion(:status, [:queued, :processing, :completed, :failed])
    |> validate_inclusion(:task_type, [:text_gen, :image_gen])
    |> validate_number(:progress, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
  end
end
