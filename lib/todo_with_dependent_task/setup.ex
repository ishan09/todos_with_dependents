defmodule TodoWithDependentTask.Setup do
  alias TodoWithDependentTask.Todo.{Task, TaskGroup}
  alias TodoWithDependentTask.Repo

  def run() do
    task_group_1 = %TaskGroup{} |> TaskGroup.changeset(%{title: "Task Group 1"}) |> Repo.insert!()

    task_group_2 = %TaskGroup{} |> TaskGroup.changeset(%{title: "Task Group 2"}) |> Repo.insert!()

    task_1_1 =
      %Task{}
      |> Task.changeset(%{
        description: "Completed Task",
        is_completed: true,
        task_group_id: task_group_2.id
      })
      |> Repo.insert!()

    %Task{}
    |> Task.changeset(%{
      description: "Locked Task",
      task_group_id: task_group_2.id,
      child_tasks: [
        %{description: "Incomplete Task", task_group_id: task_group_2.id}
      ]
    })
    |> Repo.insert!()

    %Task{}
    |> Task.changeset(%{
      description: "Task 3",
      is_completed: false,
      task_group_id: task_group_1.id,
      child_tasks: [
        %{description: "Task 3.1", task_group_id: task_group_1.id, is_completed: true},
        %{
          description: "Task 3.2",
          task_group_id: task_group_1.id,
          child_tasks: [%{description: "Task 3.2.1", task_group_id: task_group_1.id}]
        }
      ]
    })
    |> Repo.insert!()
  end
end
