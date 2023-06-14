defmodule TurnStile.Alerts.Alert do
  use Ecto.Schema
  import Ecto.Changeset

  schema "alerts" do
    field :title, :string
    field :body, :string
    field :to, :string
    field :from, :string
    field :alert_category, :string
    field :alert_format, :string
    belongs_to :employee, TurnStile.Staff.Employee
    belongs_to :user, TurnStile.Patients.User
    timestamps()
  end

  @doc false
  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [:title, :body, :to, :from, :alert_category, :alert_format, :employee_id, :user_id])
  end
end
