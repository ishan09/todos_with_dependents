defmodule TodoWithDependentTaskWeb.TaskGroupLive.Index do
  use TodoWithDependentTaskWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :task_groups, list_task_groups())}
  end

  defp list_task_groups() do
    TodoWithDependentTask.Todo.list_task_groups()
    |> Enum.map(fn task_group ->
      %{
        id: task_group.id,
        title: task_group.title,
        summary: get_task_group_summary(task_group)
      }
    end)
  end

  defp get_task_group_summary(%{tasks: tasks}) when is_list(tasks) do
    {complete, total} =
      tasks
      |> Enum.reduce(
        {0, 0},
        fn task, {complete, total} ->
          if task.is_completed do
            {complete + 1, total + 1}
          else
            {complete, total + 1}
          end
        end
      )

    "#{complete} OF #{total} TASK COMPLETE"
  end

  defp get_task_group_summary(_) do
    ""
  end
end
