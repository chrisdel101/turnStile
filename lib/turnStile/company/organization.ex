defmodule TurnStile.Company.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organizations" do
    field :email, :string
    field :name, :string
    field :slug, :string
    field :phone, :string
    has_many :admin, TurnStile.Staff.Admin
    timestamps()
  end

  @doc false
  def changeset(organization, attrs) do
    # IO.inspect(attrs)
    organization
    |> cast(attrs, [:name, :email, :phone, :slug])
    |> validate_required([:name, :email, :phone, :slug])
  end
end
