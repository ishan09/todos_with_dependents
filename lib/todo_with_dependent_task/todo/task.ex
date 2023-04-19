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
    task =
      task
      |> Repo.preload([:child_tasks, :parent_tasks])

    task
    |> cast(attrs, [:description, :is_completed, :task_group_id])
    |> validate_required([:description, :task_group_id])
    |> maybe_put_assoc_tasks(task,:child_tasks, attrs)
    |> maybe_put_assoc_tasks(task, :parent_tasks, attrs)
  end

  defp maybe_put_assoc_tasks(changeset, task, :child_tasks, %{"child_tasks" => child_tasks}) do
    maybe_put_assoc_tasks(changeset, task, :child_tasks, %{child_tasks: child_tasks})
  end

  defp maybe_put_assoc_tasks(changeset, task, :child_tasks, %{child_tasks: child_tasks} = _attrs) do
    child_tasks = reject_self_and_parent_tasks(child_tasks, task)
    changeset |> put_assoc(:child_tasks, child_tasks)
  end

  defp maybe_put_assoc_tasks( changeset, task, :parent_tasks, %{"parent_tasks" => parent_tasks}) do
    maybe_put_assoc_tasks( changeset, task, :parent_tasks, %{parent_tasks: parent_tasks})
  end

  defp maybe_put_assoc_tasks( changeset, task, :parent_tasks, %{parent_tasks: parent_tasks}) do
    parent_tasks = reject_self_and_child_tasks(parent_tasks, task)
    changeset |> put_assoc(:parent_tasks, parent_tasks)
  end

  defp maybe_put_assoc_tasks(changeset, _,_, _), do: changeset

  defp reject_self_and_child_tasks(new_associated_tasks, %Task{id: nil}), do: new_associated_tasks

  defp reject_self_and_child_tasks(new_associated_tasks, task) do
    new_associated_tasks |> Enum.reject(& Map.has_key?(&1, :id) && (&1.id == task.id || Enum.any?(task.child_tasks, fn child_task -> child_task.id == &1.id end) ))
  end

  defp reject_self_and_parent_tasks(new_associated_tasks, task) do
    new_associated_tasks
    |> Enum.reject( fn new_associated_task ->  Map.has_key?(new_associated_task, :id) && (new_associated_task.id == task.id || Enum.any?(task.parent_tasks, fn parent_task -> parent_task.id == new_associated_task.id end) ) end)
  end




end
