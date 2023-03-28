defmodule TodoWithDependentTask.Todo.Task do
  use Ecto.Schema
  import Ecto.Changeset
  alias TodoWithDependentTask.Repo
  alias TodoWithDependentTask.Todo.{Task, TaskGroup}

  schema "tasks" do
    field :description, :string
    field :is_completed, :boolean, default: false
    field :is_locked, :boolean, virtual: true
    belongs_to :task_group, TaskGroup

    many_to_many(:parent_tasks, Task,
      join_through: "task_dependencies",
      join_keys: [child_task_id: :id, parent_task_id: :id],
      on_replace: :delete
    )

    many_to_many(:child_tasks, Task,
      join_through: "task_dependencies",
      join_keys: [parent_task_id: :id, child_task_id: :id],
      on_replace: :delete
    )

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task = Repo.preload(task, :child_tasks)

    task
    |> cast(attrs, [:description, :is_completed, :task_group_id])
    |> validate_required([:description, :task_group_id])
    |> maybe_put_assoc_child_tasks(task, attrs)
  end

  defp maybe_put_assoc_child_tasks(changeset, task, %{child_tasks: _child_tasks} = attrs) do
    changeset
    |> put_assoc(:child_tasks, get_child_tasks(task, attrs))
  end

  defp maybe_put_assoc_child_tasks(changeset, _, _), do: changeset

  defp get_child_tasks(task, %{child_tasks: child_tasks}) when is_list(child_tasks) do
    (task.child_tasks || []) ++ child_tasks
  end

  defp get_child_tasks(task, _) do
    task.child_tasks || []
  end
end
