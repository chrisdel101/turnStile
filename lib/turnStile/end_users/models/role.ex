defmodule TurnStile.Role do
  use Ecto.Schema
  import Ecto.Changeset

  schema "roles" do
    field :name, :string
    field :value, :string
    belongs_to :employee, TurnStile.Staff.Employee
    belongs_to :organization, TurnStile.Company.Organization

    timestamps()
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :value])
    |> validate_required([:name, :value])
  end
end
