defmodule TodoWithDependentTaskWeb.TaskGroupLive.Show do
  use TodoWithDependentTaskWeb, :live_view
  import Icons

  alias TodoWithDependentTask.Todo.{TaskGroup, Task}
  alias TodoWithDependentTask.Todo
  alias TodoWithDependentTask.MultiSelect.SelectOption
  alias TodoWithDependentTaskWeb.MultiSelectComponent


  def mount(%{"id" => id} = params, _session, socket) do
    # IO.inspect(params, label: "show.ex: 8:: in  mount params")
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

  def handle_event("add-new", params, socket) do
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
        Enum.any?(socket.assigns.parent_tasks_selectable_options, & &1.selected && &1.id == task.id )
      end)

      Map.merge(task_params, %{"parent_tasks" =>  selected_parent_tasks})
  end



  defp get_task_group(id) do
    Todo.get_task_group(id)
    |> task_group_view()
  end

  defp get_task(id) do
    Todo.get_task(id, [:parent_tasks])
  end

  defp task_group_view(%TaskGroup{} = task_group) do
    %{
      id: task_group.id,
      title: task_group.title,
      tasks: Enum.map(task_group.tasks, &task_view/1) |> Enum.sort_by(& &1.id)
    }
  end

  defp task_view(task) do
    # %{
    #   id: task.id,
    #   description: task.description,
    #   is_completed: task.is_completed,
    #   is_locked: Enum.any?(task.child_tasks, &(!&1.is_completed))
    # }
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


  defp to_select_options(tasks, task) do
    parent_tasks =
      case task.parent_tasks do
        parent_tasks when is_list(parent_tasks) -> parent_tasks
        _ -> []
      end

    tasks
    |> Enum.map(fn t ->
      %SelectOption{id: t.id, label: t.description, selected: Enum.any?(parent_tasks, & &1.id == t.id)}
    end)
    |> Enum.filter(& &1.id != task.id)
  end

  defp toggle_task(id) do
    Todo.toggle_task(id)
  end
end
