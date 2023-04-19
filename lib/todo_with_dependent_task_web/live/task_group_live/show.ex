defmodule TodoWithDependentTaskWeb.TaskGroupLive.Show do
  use TodoWithDependentTaskWeb, :live_view
  import Icons

  alias TodoWithDependentTask.Todo.{TaskGroup, Task}
  alias TodoWithDependentTask.Todo
  alias TodoWithDependentTask.MultiSelect.SelectOption
  alias TodoWithDependentTaskWeb.MultiSelectComponent


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

  def handle_event("add-new", _params, socket) do
      {:noreply, push_patch(socket, to: Routes.task_group_show_path(socket, :new, socket.assigns.task_group.id)) }
  end

  def handle_event("edit-task", params, socket) do
      %{"task_id" => task_id} = params
      {:noreply, push_patch(socket, to: Routes.task_group_show_path(socket, :edit, socket.assigns.task_group.id, task_id)) }
  end

    def handle_event("delete-task", params, socket) do
      {:noreply,  delete_task(socket, params)}
  end

  def handle_event("validate", params, socket) do
      changeset =
        socket.assigns.task
        |> Task.changeset( Map.get(params, "task", %{}))
        |> Map.put(:action, :validate)
      {:noreply, assign(socket, :changeset, changeset) }
  end

  def handle_event("save", %{"task" => task_params}, socket) do
    task_params = add_parent_tasks_params(task_params, socket)
    save_task(socket, socket.assigns.live_action, task_params)
  end

  def handle_info({:updated_parent_tasks, options}, socket) do
    IO.inspect(options, label: "show.ex: 53:: options")
    {:noreply, assign(socket, :parent_tasks_selectable_options, options)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Task")
    |> assign(:changeset, Task.changeset(%Task{}, %{}) )
    |> assign(:task, %Task{} )
    |> assign(:parent_tasks_selectable_options, to_select_options(socket.assigns.task_group.tasks, %Task{}))

  end

  defp apply_action(socket, :edit, %{"task_id" => task_id}) do
    task = get_task(task_id)
    socket
    |> assign(:page_title, "New Task")
    |> assign(:changeset, Task.changeset(task, %{}))
    |> assign(:task, task )
    |> assign(:parent_tasks_selectable_options, to_select_options(socket.assigns.task_group.tasks, task))
  end


  defp apply_action(socket, _, _) do
    socket
  end


  defp add_parent_tasks_params(task_params, socket) do
    selected_parent_tasks =
      socket.assigns.task_group.tasks
      |> Enum.filter(fn task ->
        Enum.any?(socket.assigns.parent_tasks_selectable_options, & &1.selected in [true, "true"] && &1.id == task.id )
      end)
      IO.inspect(selected_parent_tasks, label: "show.ex: 87:: selected_parent_tasks")
      Map.merge(task_params, %{"parent_tasks" =>  selected_parent_tasks})
  end



  defp get_task_group(id) do
    Todo.get_task_group(id)
    |> task_group_view()
  end

  defp get_task(id) do
    Todo.get_task(id, [:parent_tasks, :child_tasks])
  end

  defp task_group_view(%TaskGroup{} = task_group) do
    %{
      id: task_group.id,
      title: task_group.title,
      tasks: Enum.map(task_group.tasks, &task_view/1) |> Enum.sort_by(& &1.id)
    }
  end

  defp task_view(task) do
    Map.replace(task, :is_locked, Enum.any?(task.child_tasks, &(!&1.is_completed)))
  end

  defp save_task(socket, :edit, task_params) do
    case Todo.update_task(socket.assigns.task, task_params) do
      {:ok, _task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task updated successfully")
         |> push_redirect(to: Routes.task_group_show_path(socket, :show, socket.assigns.task_group.id))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_task(socket, :new, task_params) do
    case Todo.create_task(task_params) do
      {:ok, _task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task created successfully")
         |> push_redirect(to: Routes.task_group_show_path(socket, :show, socket.assigns.task_group.id))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp delete_task(socket, %{"task_id" => task_id}) do
    with %Task{} = task <- Todo.get_task(task_id),
    {:ok, _task} <- Todo.delete_task(task),
    task_group_id <- socket.assigns.task_group.id do
      assign(socket, :task_group, get_task_group(task_group_id))
    end
  end


  defp to_select_options(available_tasks, task) do
    parent_tasks =
      case task.parent_tasks do
        parent_tasks when is_list(parent_tasks) -> parent_tasks
        _ -> []
      end

    available_tasks
    |> reject_self_completed_and_child_tasks(task)
    |> Enum.map(fn t ->
      %SelectOption{id: t.id, label: t.description, selected: Enum.any?(parent_tasks, & &1.id == t.id)}
    end)
  end

  defp reject_self_completed_and_child_tasks(available_tasks, %Task{id: nil}), do: available_tasks

  defp reject_self_completed_and_child_tasks(available_tasks, task) do
    available_tasks |> Enum.reject(& &1.id == task.id || &1.is_completed || Enum.any?(task.child_tasks, fn child_task -> child_task.id == &1.id end))
  end

  defp toggle_task(id) do
    Todo.toggle_task(id)
  end
end
