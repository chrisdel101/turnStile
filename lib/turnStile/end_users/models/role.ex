defmodule TurnStile.Roles.Role do
  use Ecto.Schema
  import Ecto.Changeset

  schema "roles" do
    field :name, :string
    field :value, :string
    many_to_many :employees, TurnStile.Staff.Employee, join_through: "organization_employee_roles"
    # belongs_to :organization, TurnStile.Company.Organization

    timestamps()
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :value])
    |> validate_required([:name, :value])
  end
end
