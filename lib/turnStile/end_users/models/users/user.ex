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
    field :user_alert_status, :string, default: UserAlertStatusTypesMap.get_user_status("UNALERTED")
    belongs_to :employee, TurnStile.Staff.Employee # most recent employee to access this user
    has_many :alerts, TurnStile.Alerts.Alert
    belongs_to :organization, TurnStile.Company.Organization
    field :confirmed_at, :naive_datetime



    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :health_card_num, :employee_id, :is_active?, :user_alert_status])
    |> validate_required([:first_name, :last_name, :email, :phone, :health_card_num, :is_active?, :user_alert_status])
  end
  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

end
