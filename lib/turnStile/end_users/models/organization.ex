defmodule TurnStile.Company.Organization do
  use Ecto.Schema
  import Ecto.Changeset


  schema "organizations" do
    field :org_email, :string
    field :name, :string
    field :slug, :string
    field :phone, :string
    has_many :employee, TurnStile.Staff.Employee
    has_many :owner, TurnStile.Staff.Owner

    embeds_one :owner_user, TurnStile.Staff.Employee do
      field :first_name, :string
      field :last_name, :string
      field :email, :string
      field :password, :string, virtual: true, redact: true
    end
    timestamps()


  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :org_email, :phone, :slug])
    |> validate_required([:name, :slug])
    |> cast_embed(:owner_user, required: true, with: &owner_user_changeset/2)
  end

  def owner_user_changeset(owner_user_changeset, attrs \\ %{}) do
    owner_user_changeset
    |> cast(attrs, [:first_name, :last_name, :email, :password])
    |> validate_required([:first_name, :last_name, :email, :password])
    |> validate_email()
  end

  defp validate_email(changeset) do
    IO.inspect(changeset)
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> validate_confirmation(:email, message: "Emails do not match")
    |> validate_confirmation(:password, message: "Passwords do not match")
  end
end
