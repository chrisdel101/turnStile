defmodule TurnStile.Patients.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :first_name, :string
    field :health_card_num, :integer
    field :last_name, :string
    field :phone, :string
    belongs_to :employee, TurnStile.Staff.Employee
    has_many :alerts, TurnStile.Alert


    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :health_card_num, :employee_id])
    |> validate_required([:first_name, :last_name, :email, :phone, :health_card_num,])
  end
end
