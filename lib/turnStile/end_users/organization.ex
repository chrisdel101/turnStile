defmodule TurnStile.Company.Organization do
  use Ecto.Schema
  import Ecto.Changeset


  schema "organizations" do
    field :email, :string
    field :name, :string
    field :slug, :string
    field :phone, :string
    field :timezone, :string, default: "Etc/UTC"
    # org has many employees; employees can belong to many organiztions
    many_to_many :employees, TurnStile.Staff.Employee, join_through: "organization_employees", on_replace: :delete
    has_many :roles, TurnStile.Roles.Role
    # has_many :roles, TurnStile.Roles.Role
    # org has many owners; owners can have many orgs
    many_to_many :owners, TurnStile.Staff.Owner, join_through: "organization_owners"
    has_many :users, TurnStile.Patients.User
    has_many :alerts, TurnStile.Alerts.Alert

    timestamps()


  end

  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :email, :phone, :slug, :timezone])
    |> validate_required([:name, :slug])
    |> validate_email()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end
end