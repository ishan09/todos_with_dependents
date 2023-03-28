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
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> unique_constraint(:title)
  end
end
