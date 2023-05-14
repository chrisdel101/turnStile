defmodule TurnStile.Alert do
  use Ecto.Schema
  import Ecto.Changeset

  schema "alerts" do
    field :text, :string
    belongs_to :employee, TurnStile.Staff.Employee
    belongs_to :user, TurnStile.Patients.User
    timestamps()
  end

  @doc false
  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [:text])
    |> validate_required([:text])
  end
end
