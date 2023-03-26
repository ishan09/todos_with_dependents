defmodule TodoWithDependentTask.Repo.Migrations.AddTodoGroups do
  use Ecto.Migration

  def change do
    create table(:task_groups) do
      add :title, :string

      timestamps()
    end

    create unique_index(:task_groups, [:title])
  end
end
