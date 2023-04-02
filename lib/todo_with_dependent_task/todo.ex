defmodule TodoWithDependentTask.Todo do
  import Ecto.Query

  alias Ecto.Changeset
  alias TodoWithDependentTask.Todo.{Task, TaskGroup}
  alias TodoWithDependentTask.Repo
  alias Ecto.Multi

  @doc """
  Create a TaskGroup
  """
  @spec create_task_group(map()) :: {:ok, %TaskGroup{}} | {:error, %Changeset{}}
  def create_task_group(attrs) do
    %TaskGroup{}
    |> TaskGroup.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Create a Task
  """

  @spec create_task(map()) :: {:ok, %Task{}} | {:error, %Changeset{}}
  def create_task(attrs) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  List all the task groups with list of associated tasks
  """
  @spec list_task_groups :: [%TaskGroup{}]
  def list_task_groups() do
    from(tg in TaskGroup,
      left_join: t in Task,
      on: tg.id == t.task_group_id,
      preload: [tasks: t],
      order_by: t.inserted_at
    )
    |> Repo.all()
  end

  @doc """
  Get the task groups with list of associated tasks
  """
  @spec get_task_group(any) :: nil | %TaskGroup{tasks: [%Task{}]}
  def get_task_group(id) do
    from(tg in TaskGroup,
      left_join: t in Task,
      on: tg.id == t.task_group_id,
      left_join: td in "task_dependencies",
      on: td.parent_task_id == t.id,
      left_join: ct in Task,
      on: td.child_task_id == ct.id,
      preload: [tasks: {t, [child_tasks: ct]}],
      where: tg.id == ^id,
      order_by: t.inserted_at
    )
    |> Repo.one()
  end

  @doc """
  Toggle task complete status.

  If the dependent task is marked as incomplete, the parent tasks are marked as incomplete.
  """
  @spec toggle_task(integer()) :: {:ok, map()} | {:error, any()}
  def toggle_task(task_id) do
    task =
      Task
      |> Repo.get!(task_id)

    task
    |> toggle_task_(!task.is_completed)
    |> Enum.reduce(Multi.new(), fn task_changeset, multi ->
      Multi.update(multi, String.to_atom("update-#{DateTime.utc_now()}"), task_changeset)
    end)
    |> Repo.transaction()
  end

  defp toggle_task_(task, is_completed)

  defp toggle_task_(task, false) do
    task = task |> Repo.preload(:parent_tasks)

    parent_task_changesets =
      Enum.map(task.parent_tasks, &toggle_task_(&1, false)) |> List.flatten()

    [Task.changeset(task, %{is_completed: false}) | parent_task_changesets]
  end

  defp toggle_task_(task, true), do: [Task.changeset(task, %{is_completed: true})]
end
