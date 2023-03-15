defmodule TurnStile.Company.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organizations" do
    field :email, :string
    field :name, :string
    field :phone, :string

    timestamps()
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :email, :phone])
    |> validate_required([:name, :email, :phone])
  end
end
