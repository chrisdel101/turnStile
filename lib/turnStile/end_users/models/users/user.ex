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
    field :alert_format_set, :string, default: AlertFormatTypesMap.get_alert("SMS")
    belongs_to :employee, TurnStile.Staff.Employee # most recent employee to access this user
    has_many :alerts, TurnStile.Alerts.Alert
    belongs_to :organization, TurnStile.Company.Organization
    field :confirmed_at, :naive_datetime



    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :health_card_num, :employee_id, :is_active?, :user_alert_status, :alert_format_set])
    |> validate_required([:first_name, :last_name, :health_card_num, :is_active?, :user_alert_status, :alert_format_set])
    # |> validate_alert_format_matches_alert_format_set()
  end
  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @spec validate_alert_format_matches_alert_format_set(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_alert_format_matches_alert_format_set(changeset) do
    # IO.inspect(changeset, label: "xxxxxxxxxxxxxx")
    # IO.inspect(changeset.data, label: "yyyyy")
    alert_format_changes = get_change(changeset, :alert_format_set)
    phone_setting = Map.get(changeset.data, :alert_format_set)
    email = get_change(changeset, :email)
    phone = get_change(changeset, :phone)
    # IO.inspect(changeset.data, label: "xxxxxxxxxxxxxx")
    # IO.inspect(phone, label: "xxxxxxxxxxxxxx")
    cond do
      # check for email change
      alert_format_changes === AlertFormatTypesMap.get_alert("EMAIL") && is_nil(email) ->
        changeset  = add_error(changeset, :email, "Email type is chosen. Must have an email.")
        changeset
      # check for default setting and no email change; needs phone
      alert_format_changes !== AlertFormatTypesMap.get_alert("EMAIL") &&
        is_nil(phone) ->
        IO.puts("FIRED1")
        changeset  =add_error(changeset, :phone, "SMS type is chosen. Must have a phone number.")
          changeset
      # Clear the error for the email field when switching to SMS
      alert_format_changes !== AlertFormatTypesMap.get_alert("EMAIL") &&
        !is_nil(email) ->
        changeset
        |> delete_change(:email)
        |> put_change(:email, nil)

      true ->
        changeset
    end
  end




end
