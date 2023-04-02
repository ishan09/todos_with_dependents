defmodule TodoWithDependentTask.TodoFixtures do
  alias TodoWithDependentTask.Todo

  def task_group_fixtures(attrs \\ %{}) do
    {:ok, task_group} =
      %{title: "Task Group #{System.unique_integer()}"}
      |> Map.merge(attrs)
      |> Todo.create_task_group()

    task_group
  end

  def task_fixtures(attrs \\ %{}) do
    {:ok, task} =
      %{description: "Task #{System.unique_integer()}"}
      |> Map.merge(attrs)
      |> Todo.create_task()

    task
  end
end
