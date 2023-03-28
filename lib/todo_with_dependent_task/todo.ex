defmodule TodoWithDependentTask.Todo do
  import Ecto.Query

  alias TodoWithDependentTask.Todo.{Task, TaskGroup}
  alias TodoWithDependentTask.Repo
  alias Ecto.Multi

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

  @spec get_task_group(any) :: nil | %TaskGroup{}
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

  defp toggle_task_(task, false) do
    task = task |> Repo.preload(:parent_tasks)

    parent_task_changesets =
      Enum.map(task.parent_tasks, &toggle_task_(&1, false)) |> List.flatten()

    [Task.changeset(task, %{is_completed: false}) | parent_task_changesets]
  end

  defp toggle_task_(task, true), do: [Task.changeset(task, %{is_completed: true})]
end
