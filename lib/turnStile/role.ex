defmodule TurnStile.Role do
  use Ecto.Schema
  import Ecto.Changeset

  schema "roles" do

    field :name, :string
    field :value, :string
    field :organization_id, :integer
    belongs_to :employee, TurnStile.Staff.Employee, foreign_key: :employee_id  # belongs_to :organization, TurnStile.Company.Organization, foreign_key: :organization_id

    timestamps()
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :value, :organization_id])
    |> validate_required([:name, :value, :organization_id])
  end
end
