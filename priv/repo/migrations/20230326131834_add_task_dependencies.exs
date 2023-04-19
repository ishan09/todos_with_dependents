defmodule TodoWithDependentTask.Repo.Migrations.AddTaskDependencies do
  use Ecto.Migration

  def change do
    create table(:task_dependencies, primary_key: false) do
      add :parent_task_id, references(:tasks, on_delete: :delete_all), primary_key: true
      add :child_task_id, references(:tasks, on_delete: :delete_all), primary_key: true
    end

    create unique_index(:task_dependencies, [:parent_task_id, :child_task_id],
             name: :task_dependencies_parent_task_id_child_task_id_index
           )

    create unique_index(:task_dependencies, [:child_task_id, :parent_task_id],
             name: :task_dependencies_child_task_id_parent_task_id_index
           )
  end
end
