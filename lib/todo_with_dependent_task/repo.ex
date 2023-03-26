defmodule TodoWithDependentTask.Repo do
  use Ecto.Repo,
    otp_app: :todo_with_dependent_task,
    adapter: Ecto.Adapters.Postgres
end
