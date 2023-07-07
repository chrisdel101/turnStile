defmodule TurnStile.Alerts.Alert do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  Alert Schema
  -alerts belong to one user
  -alerts belong to one employee
  -alerts belong to one organization
  """
  schema "alerts" do
    field :title, :string
    field :body, :string
    field :to, :string
    field :from, :string
    field :alert_category, :string
    field :alert_format, :string
    belongs_to :employee, TurnStile.Staff.Employee
    belongs_to :user, TurnStile.Patients.User
    belongs_to :organization, TurnStile.Company.Organization
    timestamps()
  end

  @doc false
  def changeset(alert, attrs, validate? \\ false) do
    alert
    |> cast(attrs, [:title, :body, :to, :from, :alert_category, :alert_format, :employee_id, :user_id])
    |> validate_when_required(validate?, [:title, :body, :to, :from])
  end

  defp validate_when_required(alert, validate?, attrs) do
    if validate? do
      alert
      |> validate_required(attrs)
    else
      alert
    end
  end
end
