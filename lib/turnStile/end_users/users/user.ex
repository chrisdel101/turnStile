defmodule TurnStile.Patients.User do
  use Ecto.Schema
  import Ecto.Changeset
  @now NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  schema "users" do
    field :email, :string
    field :first_name, :string
    field :health_card_num, :integer
    field :last_name, :string
    field :phone, :string
    field :date_of_birth, :date
    field :is_active?, :boolean, default: true
    field :user_alert_status, :string,
      default: UserAlertStatusTypesMap.get_user_status("UNALERTED")
    field :alert_format_set, :string, default: AlertFormatTypesMap.get_alert("SMS")
    # will be most recent employee to access this user
    belongs_to :employee, TurnStile.Staff.Employee
    has_many :alerts, TurnStile.Alerts.Alert , on_delete: :delete_all
    belongs_to :organization, TurnStile.Company.Organization

    field :confirmed_at, :naive_datetime
    field :activated_at, :naive_datetime
    field :deactivated_at, :naive_datetime

    timestamps()
  end
  @doc false
  def create_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :health_card_num, :employee_id, :is_active?, :user_alert_status, :alert_format_set, :date_of_birth])
    |> validate_required([:first_name, :last_name, :health_card_num, :is_active?, :user_alert_status])
    |> validate_alert_format_matches_alert_format_set()

  end
  # same as create but w/ not default - since overwrites changes
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :health_card_num, :employee_id, :is_active?, :user_alert_status, :alert_format_set, :date_of_birth])
    |> validate_required([:first_name, :last_name, :health_card_num, :is_active?, :user_alert_status])
    |>
    validate_alert_format_matches_alert_format_set()
    |> unique_constraint(:health_card_num, message: "A member with this number already exists. Duplicates cannot exist for this field.")
    # to make this an error on the form use the name: field; stops server exception
    |> unique_constraint([:phone, :organization_id, :is_active?], message: "A user with this phone number is already active. Mutiple users with the same number cannot be active.", name: :users_phone_organization_id_is_active_index)
  end


  @doc """
  Confirms the account by setting `confirmed_at`.
  used in confirm_user_email_account_token_multi, confirm_user_account_via_init_valid_sms
  """
  def confirm_account_valid(user) do
    change(user, confirmed_at: @now)
  end
  # validate field matches alert_format_set on upsert form
  def validate_alert_format_matches_alert_format_set(changeset) do

    alert_format_changes = get_field(changeset, :alert_format_set)
    email = get_field(changeset, :email)
    phone = get_field(changeset, :phone)
    # IO.inspect(alert_format_changes, label: "alert_format_changes")
    # IO.inspect(email, label: "email")
    # IO.inspect(phone, label: "phone")
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
end
