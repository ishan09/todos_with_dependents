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

  # @spec changeset(%Task{}, map.t):: %Ecto.Changeset{}
  def changeset(task, attrs) do
    task = Repo.preload(task, [:child_tasks, :parent_tasks])
    IO.inspect(attrs, label: "task.ex: 31:: attrs")

    task
    |> cast(attrs, [:description, :is_completed, :task_group_id])
    |> validate_required([:description, :task_group_id])
    |> maybe_put_assoc_tasks(task,:child_tasks, attrs)
    |> maybe_put_assoc_tasks(task, :parent_tasks, attrs)
  end

  defp maybe_put_assoc_tasks(changeset, task, :child_tasks, %{"child_tasks" => child_tasks}) do
    maybe_put_assoc_tasks(changeset, task, :child_tasks, %{child_tasks: child_tasks})
  end

  defp maybe_put_assoc_tasks(changeset, task, :child_tasks, %{child_tasks: child_tasks} = attrs) do
    child_tasks =
      ((task.child_tasks || []) ++ child_tasks)
      |> Enum.uniq(& &1.id)

    changeset
    |> put_assoc(:child_tasks, child_tasks)
  end

  defp maybe_put_assoc_tasks( changeset, task, :parent_tasks, %{"parent_tasks" => parent_tasks}) do
    maybe_put_assoc_tasks( changeset, task, :parent_tasks, %{parent_tasks: parent_tasks})
  end

  defp maybe_put_assoc_tasks( changeset, task, :parent_tasks, %{parent_tasks: parent_tasks}) do
    parent_tasks =
      ((task.parent_tasks || []) ++ parent_tasks)
      |> Enum.uniq(& &1.id)

      changeset
      |> put_assoc(:parent_tasks, parent_tasks)
  end

  defp maybe_put_assoc_tasks(changeset, _,_, _), do: changeset

end
