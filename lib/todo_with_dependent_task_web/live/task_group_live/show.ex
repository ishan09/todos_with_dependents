defmodule TodoWithDependentTaskWeb.TaskGroupLive.Show do
  use TodoWithDependentTaskWeb, :live_view

  alias TodoWithDependentTask.Todo.TaskGroup
  alias TodoWithDependentTask.Todo

  def mount(%{"id" => id} = _params, _session, socket) do
    {:ok, assign(socket, :task_group, get_task_group(id))}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_event("toggle", params, socket) do
    with %{"id" => id} = params,
         {:ok, _} <- toggle_task(id) do
      {:noreply, assign(socket, task_group: get_task_group(socket.assigns.task_group.id))}
    end
  end

  defp apply_action(socket, _, _) do
    socket
  end

  defp get_task_group(id) do
    Todo.get_task_group(id)
    |> task_group_view()
  end

  defp task_group_view(%TaskGroup{} = task_group) do
    %{
      id: task_group.id,
      title: task_group.title,
      tasks: Enum.map(task_group.tasks, &task_view/1) |> Enum.sort_by(& &1.id)
    }
  end

  defp task_view(task) do
    %{
      id: task.id,
      description: task.description,
      is_completed: task.is_completed,
      is_locked: Enum.any?(task.child_tasks, &(!&1.is_completed))
    }
  end

  defp toggle_task(id) do
    Todo.toggle_task(id)
  end
end
