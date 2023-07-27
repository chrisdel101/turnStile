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
    field :user_alert_status, :string,
      default: UserAlertStatusTypesMap.get_user_status("UNALERTED")
    field :alert_format_set, :string
    # most recent employee to access this user
    belongs_to :employee, TurnStile.Staff.Employee
    has_many :alerts, TurnStile.Alerts.Alert
    belongs_to :organization, TurnStile.Company.Organization
    field :confirmed_at, :naive_datetime

    timestamps()
  end

  @doc false
  def create_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :health_card_num, :employee_id, :is_active?, :user_alert_status, :alert_format_set])
    |> apply_defaults(attrs)
    |> validate_required([:first_name, :last_name, :health_card_num, :is_active?, :user_alert_status])
    |> validate_alert_format_matches_alert_format_set()
  end
  # same as create but w/ not default - since overwrites changes
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :health_card_num, :employee_id, :is_active?, :user_alert_status, :alert_format_set])
    |> validate_required([:first_name, :last_name, :health_card_num, :is_active?, :user_alert_status])
    |> validate_alert_format_matches_alert_format_set()
  end


  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end
  # validate field matches alert_format_set on upsert form
  def validate_alert_format_matches_alert_format_set(changeset) do

    alert_format_changes = get_change(changeset, :alert_format_set)
    email = get_change(changeset, :email)
    phone = get_change(changeset, :phone)
    IO.inspect(alert_format_changes, label: "alert_format_changes")
    cond do
      # check for email change
      alert_format_changes === AlertFormatTypesMap.get_alert("EMAIL") && is_nil(email) ->
        changeset = add_error(changeset, :email, "Email type is chosen on User. Must have an email.")
        changeset

      # check for default setting and no email change; needs phone
      alert_format_changes === AlertFormatTypesMap.get_alert("SMS") && is_nil(phone) ->
        changeset = add_error(changeset, :phone, "SMS type is chosen on User. Must have a phone number.")
        changeset
      true ->
        changeset
      end
    end
    # apply value to alert_format_set here; setting default on model causes an error
    defp apply_defaults(changeset, attrs) do
      if (Map.get(attrs, :alert_format_set) ||  Map.get(attrs, "alert_format_set")) || get_change(changeset, :alert_format_set) do
        # :alert_format_set has already been set, no need to change the default value
        changeset
      else
        # :alert_format_set has not been set, apply the default value
        change(changeset, alert_format_set: AlertFormatTypesMap.get_alert("SMS"))
      end
    end
end
