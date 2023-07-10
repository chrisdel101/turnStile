defmodule TurnStile.Patients.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :first_name, :string
    field :health_card_num, :integer
    field :last_name, :string
    field :phone, :string
    field :is_active?, :boolean, default: true
    field :user_alert_status, :string, default: UserStatusTypesMap.get_user_status("UNALERTED")
    belongs_to :employee, TurnStile.Staff.Employee
    has_many :alerts, TurnStile.Alerts.Alert
    belongs_to :organization, TurnStile.Company.Organization



    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :health_card_num, :employee_id, :is_active?, :alert_status])
    |> validate_required([:first_name, :last_name, :email, :phone, :health_card_num, :is_active?, :alert_status])
  end
end
