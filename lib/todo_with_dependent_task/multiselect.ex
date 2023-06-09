defmodule TodoWithDependentTask.MultiSelect do
  use Ecto.Schema

  embedded_schema do
    embeds_many :options, TodoWithDependentTask.MultiSelect.SelectOption
  end

  defmodule SelectOption do
    use Ecto.Schema

    embedded_schema do
      field :selected, :boolean, default: false
      field :label, :string
    end
  end
end
