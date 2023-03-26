defmodule TodoWithDependentTask.Repo.Migrations.AddTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :description, :string
      add :is_completed, :boolean
      add :task_group_id, references(:task_groups)

      timestamps()
    end
  end
end
