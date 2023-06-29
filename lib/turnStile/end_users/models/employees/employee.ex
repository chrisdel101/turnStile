defmodule TurnStile.Staff.Employee do
  use Ecto.Schema
  import Ecto.Changeset
  alias TurnStile.Company

  schema "employees" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:client_type, :string)
    field(:email, :string)
    field(:password, :string, virtual: true, redact: true)
    field(:hashed_password, :string, redact: true)
    field(:confirmed_at, :naive_datetime)
    # set these fields at login
    field(:current_organization_login_id, :integer)
    field(:role_value_on_current_organization, :string, default: nil)
    field(:role_on_current_organization, :string, default: nil)
    field(:is_logged_in?, :boolean, default: false)
    field(:timezone, :string)
    # org has many employees within the company; employees belongs to many orgs
    many_to_many(:organizations, TurnStile.Company.Organization,
      join_through: "organization_employees",
      on_replace: :delete
    )

    # employee can have many roles; need limitation of one role per org
    has_many(:roles, TurnStile.Roles.Role)
    # all users created by an employee
    has_many(:users, TurnStile.Patients.User)
    # all alerts created by an employee
    has_many(:alerts, TurnStile.Alerts.Alert)
    # any employees that is an owner
    has_one(:owner, TurnStile.Staff.Owner)
    timestamps()
  end

  # should be used for changing employee info - NOT during registration
  def changeset(employee, attrs, _opts \\ []) do
    employee
    |> cast(attrs, [
      :email,
      :last_name,
      :first_name,
      :password,
      :hashed_password,
      :current_organization_login_id,
      :role_value_on_current_organization,
      :is_logged_in?,
      :role_on_current_organization
    ])
  end

  # used for building a form when registering/creating
  def creation_form_changeset(employee, attrs, opts \\ []) do
    employee
    |> cast(attrs, [:email, :last_name, :first_name, :password, :hashed_password])
    |> validate_email()
    |> validate_password(opts)
    |> hash_password(opts)
  end

  @doc """
  handle_timezone_insert
  # use custome timezone, else add one from organization
  -takes timezone from organization if employee has not set one
  -employee can override organization timezone in settings(TODO)
  -CLI use: current_organization_login_id must be set maually
  """
  defp handle_timezone_insert(changeset) do
    # IO.inspect(changeset, label: "changeset in handle_timezone")
    # if employee has not explieitly set timezone, use organization timezone
    # check no timezone ovrerride set on employee
    case !Map.get(changeset.changes, "timezone") && !Map.get(changeset.changes, :timezone) do
      true ->
        # check employee has an org
        case Map.get(changeset.changes, :current_organization_login_id) do
          nil ->
            IO.puts(
              "Error: Staff.Employee handle_timezone_insert. current_organization_login_id cannot be nil when timezone is also nil"
            )
            raise "Error: handle_timezone_insert missing organization id"

          _ ->
            # IO.inspect(changeset.changes, label: "changeset.changes in handle_timezone")
            # get timefrom organization
            organization =
              Company.get_organization(changeset.changes.current_organization_login_id)

            # IO.inspect(organization, label: "organization in handle_timezone")
            changeset = Ecto.Changeset.put_change(changeset, :timezone, organization.timezone)
            changeset
        end

      false ->
        # IO.inspect(changeset, label: "changeset in handle_timezone")
        # add timezone override
        changeset
    end
  end

  @doc """
  remove_current_organization_login_id
  -on registration current_organization_login_id is used to set timezone
  -after registration it is set back to nil unitl login
  """
  # reset field to nil; set when employee logs in
  defp remove_current_organization_login_id(changeset) do
    # IO.inspect(changeset, label: "changeset in remove_current_organization_login_id")

    changeset =
      changeset
      |> put_change(:current_organization_login_id, nil)

    # IO.inspect(changeset, label: "changeset in remove_current_organization_login_id after")
  end

  def set_current_organization_login_id(changeset, organization_id) do
    # IO.inspect(changeset, label: "changeset in remove_current_organization_login_id")

    changeset =
      changeset
      |> put_change(:current_organization_login_id, organization_id)

    # IO.inspect(changeset, label: "changeset in set_current_organization_login_id after")
  end

  @doc """
  A employee changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(employee, attrs, opts \\ []) do
    # IO.inspect(attrs, label: "attrs in registration_changeset")
    # IO.inspect(opts, label: "opts in registration_changeset")

    employee
    |> cast(attrs, [
      :email,
      :password,
      :hashed_password,
      :last_name,
      :first_name,
      :is_logged_in?,
      :current_organization_login_id,
      :timezone
    ])
    |> validate_required([:last_name, :first_name])
    |> validate_email()
    |> validate_password(opts)
    |> hash_password(opts)
    |> set_current_organization_login_id(extract_current_organization_login_id(attrs, opts))
    |> handle_timezone_insert()
    |> remove_current_organization_login_id()
  end

  # param is set or can be passed in via opts; need logic to avoid dot operator on nil
  defp extract_current_organization_login_id(attrs, opts) do
    if Map.get(attrs, "current_organization_login_id") do
      Map.get(attrs, "current_organization_login_id")
    else
      # takes opts params
      cond do
        Keyword.get(opts, :organization) !==
            nil ->
              # extact if no nil
          Keyword.get(opts, :organization).id

        Keyword.get(opts, :organization_id) !== nil ->
          Keyword.get(opts, :organization_id)

        true ->
          raise "Error: Staff.Employee extract_current_organization_login_id. current_organization_login_id is nil in both attrs and opts."
      end
    end
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> validate_confirmation(:email, message: "Emails do not match")
    |> validate_confirmation(:password, message: "Passwords do not match")
    |> unsafe_validate_unique(:email, TurnStile.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, _opts) do
    changeset
    |> validate_required([:password])
    # make it 6 in dev - change back later
    |> validate_length(:password, min: 6, max: 72)

    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
  end

  defp hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A employee changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(employee, attrs) do
    employee
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A employee changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(employee, attrs, opts \\ []) do
    employee
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
    |> validate_confirmation(:password, message: "Passwords do not match")
    |> hash_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(employee) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(employee, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no employee or the employee doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%TurnStile.Staff.Employee{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
