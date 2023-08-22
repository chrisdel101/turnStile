defmodule TurnStile.Staff.Owner do
  use Ecto.Schema
  import Ecto.Changeset

  schema "owners" do
    field :first_name, :string
    field :last_name, :string
    field :employee_id, :id
    field :role_value, :integer
    # an employees that is an owner
    belongs_to :employees, TurnStile.Staff.Employee
    # all owners within a company - can be owners of multiple companies
    many_to_many :organizations, TurnStile.Company.Organization, join_through: "organization_owners"



    timestamps()
  end

  @doc false
  def changeset(owner, attrs) do
    owner
    |> cast(attrs, [:first_name, :last_name])
    |> validate_required([:first_name, :last_name])
  end
end
