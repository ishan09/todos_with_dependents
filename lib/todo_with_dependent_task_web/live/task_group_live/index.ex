defmodule TodoWithDependentTaskWeb.TaskGroupLive.Index do
  use TodoWithDependentTaskWeb, :live_view

  alias TodoWithDependentTask.Todo.TaskGroup
  alias TodoWithDependentTask.Todo

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :task_groups, list_task_groups())}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_event("add-new", _params, socket) do
      {:noreply, push_patch(socket, to: Routes.task_group_index_path(socket, :new)) }
  end

  def handle_event("validate", params, socket) do
      changeset =
        socket.assigns.task_group
        |> TaskGroup.changeset( Map.get(params, "task_group", %{}))
        |> Map.put(:action, :validate)
      {:noreply, assign(socket, :changeset, changeset) }
  end

  def handle_event("save", %{"task_group" => task_group_params}, socket) do
    save_task_group(socket, socket.assigns.live_action, task_group_params)
  end

  defp save_task_group(socket, :new, task_group_params) do
    case Todo.create_task_group(task_group_params) do
      {:ok, _task_group} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task Group created successfully")
         |> push_redirect(to: Routes.task_group_index_path(socket, :index))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Task Group")
    |> assign(:changeset, TaskGroup.changeset(%TaskGroup{}, %{}) )
    |> assign(:task_group, %TaskGroup{} )
  end

  defp apply_action(socket, _, _) do
    socket
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
    |> Enum.sort_by(& &1.title)
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
