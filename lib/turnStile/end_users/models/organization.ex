defmodule TurnStile.Company.Organization do
  use Ecto.Schema
  import Ecto.Changeset


  schema "organizations" do
    field :email, :string
    field :name, :string
    field :slug, :string
    field :phone, :string
    # org has many employees; employees can belong to many organiztions (mostly for owners)
    many_to_many :employees, TurnStile.Staff.Employee, join_through: "organization_employees"
    has_many :roles, TurnStile.Role
    # org has many owners; owners can have many orgs
    many_to_many :owners, TurnStile.Staff.Owner, join_through: "organization_owners"

    # embeds_one :owner_employee, TurnStile.Staff.Employee do
    #   field :first_name, :string, virtual: true
    #   field :last_name, :string, virtual: true
    #   field :_email, :string, virtual: true
    #   field :password, :string, virtual: true, redact: true
    # end
    timestamps()


  end

  # create changeset of org attrs only
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :email, :phone, :slug])
    |> validate_required([:name, :slug])
  end
  # # only used to validate the new form
  # def form_changeset(organization, attrs) do
  #   organization
  #   |> cast(attrs, [:name, :email, :phone, :slug])
  #   |> validate_required([:name, :slug])
  #   |> cast_embed(:owner_employee, required: true, with: &owner_employee_changeset/2)
  # end

  # def owner_employee_changeset(owner_employee_changeset, attrs \\ %{}) do
  #   owner_employee_changeset
  #   |> cast(attrs, [:first_name, :last_name, :_email, :password])
  #   |> validate_required([:first_name, :last_name, :_email, :password])
  #   |> validate_email()
  # end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:_email])
    |> validate_format(:_email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:_email, max: 160)
    |> validate_confirmation(:_email, message: "Emails do not match")
    |> validate_confirmation(:password, message: "Passwords do not match")
  end
end
