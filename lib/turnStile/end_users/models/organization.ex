defmodule TurnStile.Company.Organization do
  use Ecto.Schema
  import Ecto.Changeset


  schema "organizations" do
    field :email, :string
    field :name, :string
    field :slug, :string
    field :phone, :string
    field :default_timezone, :string, default: "Etc/UTC"
    # org has many employees; employees can belong to many organiztions
    many_to_many :employees, TurnStile.Staff.Employee, join_through: "organization_employees"
    has_many :roles, TurnStile.Role
    # org has many owners; owners can have many orgs
    many_to_many :owners, TurnStile.Staff.Owner, join_through: "organization_owners"
    timestamps()


  end

  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :email, :phone, :slug])
    |> validate_required([:name, :slug])
    |> validate_email()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end
end
