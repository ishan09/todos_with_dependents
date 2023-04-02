defmodule TodoWithDependentTask.TodoTest do
  use TodoWithDependentTask.DataCase

  import TodoWithDependentTask.TodoFixtures
  alias TodoWithDependentTask.{Todo}
  alias TodoWithDependentTask.Todo.{Task, TaskGroup}
  alias TodoWithDependentTask.Repo

  describe "list_task_groups/0" do
    test "Return empty list when no task group present" do
      assert [] = Todo.list_task_groups()
    end

    test "Returns list of task groups present" do
      %{id: id} = task_group = task_group_fixtures()

      assert [%TaskGroup{id: ^id}] = Todo.list_task_groups()
    end
  end

  describe "get_task_group/1" do
    test "Returns nil when no TaskGroup present for given ID" do
      assert nil == Todo.get_task_group(1)
    end

    test "Returns a TaskGroup and list of tasks when a valid ID is passed" do
      %{id: id} = task_group = task_group_fixtures()
      %{id: task_id} = task_fixtures(%{task_group_id: id})
      assert %{id: ^id, tasks: [%{id: ^task_id}]} = Todo.get_task_group(id)
    end
  end

  describe "toggle_task/1" do
    setup do
      %{id: task_group_id} = task_group = task_group_fixtures()

      %{id: task_id, child_tasks: [%{id: child_task_id}]} =
        task_fixtures(%{
          task_group_id: task_group_id,
          description: "Parent task",
          is_completed: true,
          child_tasks: [
            %{task_group_id: task_group_id, description: "Child task", is_completed: true}
          ]
        })

      [task_group_id: task_group_id, task_id: task_id, child_task_id: child_task_id]
    end

    test "Mark parent tasks as incomplete when child task is marked as Incomplete", %{
      task_group_id: task_group_id,
      task_id: task_id,
      child_task_id: child_task_id
    } do
      %{id: ^task_group_id, tasks: [task1, task2]} = Todo.get_task_group(task_group_id)

      assert task1.is_completed
      assert task2.is_completed

      {:ok, _} = Todo.toggle_task(child_task_id)

      %{id: ^task_group_id, tasks: [updated_task_1, updated_task_2]} =
        Todo.get_task_group(task_group_id)

      refute updated_task_1.is_completed
      refute updated_task_2.is_completed
    end
  end
end
