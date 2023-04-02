defmodule TodoWithDependentTask.Todo.TaskGroup do
  use Ecto.Schema
  import Ecto.Changeset

  alias TodoWithDependentTask.Todo.Task

  schema "task_groups" do
    field :title, :string

    has_many :tasks, Task

    timestamps()
  end

  @doc false
  def changeset(task_group, attrs) do
    task_group
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> unique_constraint(:title)
  end
end
