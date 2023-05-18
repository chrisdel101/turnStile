defmodule TurnStile.Company.Organization do
  use Ecto.Schema
  import Ecto.Changeset


  schema "organizations" do
    field :email, :string
    field :name, :string
    field :slug, :string
    field :phone, :string
    has_many :employee, TurnStile.Staff.Employee
    has_many :owner, TurnStile.Staff.Owner

    embeds_one :owner_employee, TurnStile.Staff.Employee do
      field :first_name, :string
      field :last_name, :string
      field :_email, :string
      field :password, :string, virtual: true, redact: true
    end
    timestamps()


  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :email, :phone, :slug])
    |> validate_required([:name, :slug])
  end

  def create_changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :email, :phone, :slug])
    |> validate_required([:name, :slug])
    |> cast_embed(:owner_employee, required: true, with: &owner_employee_changeset/2)
  end

  def owner_employee_changeset(owner_employee_changeset, attrs \\ %{}) do
    owner_employee_changeset
    |> cast(attrs, [:first_name, :last_name, :_email, :password])
    |> validate_required([:first_name, :last_name, :_email, :password])
    |> validate_email()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:_email])
    |> validate_format(:_email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:_email, max: 160)
    |> validate_confirmation(:_email, message: "Emails do not match")
    |> validate_confirmation(:password, message: "Passwords do not match")
  end
end
