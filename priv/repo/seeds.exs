# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TodoWithDependentTask.Repo.insert!(%TodoWithDependentTask.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
    alias TodoWithDependentTask.Todo.{TaskGroup, Task}
    alias TodoWithDependentTask.Repo


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
