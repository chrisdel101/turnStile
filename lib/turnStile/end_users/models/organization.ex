defmodule TurnStile.Company.Organization do
  use Ecto.Schema
  import Ecto.Changeset
  alias TurnStile.Repo


  schema "organizations" do
    field :email, :string
    field :name, :string
    field :slug, :string
    field :phone, :string
    has_many :employee, TurnStile.Staff.Employee
    has_many :owner, TurnStile.Staff.Owner
    timestamps()
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :email, :phone, :slug])
    |> validate_required([:name, :slug])
  end
end
