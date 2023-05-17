defmodule TurnStile.Staff.Owner do
  use Ecto.Schema
  import Ecto.Changeset

  schema "owners" do
    field :first_name, :string
    field :last_name, :string
    field :employee_id, :id
    belongs_to :employees, TurnStile.Staff.Employee
    belongs_to :organization, TurnStile.Company.Organization



    timestamps()
  end

  @doc false
  def changeset(owner, attrs) do
    owner
    |> cast(attrs, [:first_name, :last_name])
    |> validate_required([:first_name, :last_name])
  end
end
