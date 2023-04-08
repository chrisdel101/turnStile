defmodule TurnStile.Staff.Employee do
  use Ecto.Schema
  import Ecto.Changeset


  schema "employees" do
    field :first_name, :string
    field :last_name, :string
    field :role, :string
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime
    belongs_to :organization, TurnStile.Company.Organization
    # has_many :users, WaitingRoom.Patient.User
    # employee sends alerts
    # has_many :alerts, WaitingRoom.Alert
    timestamps()
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

  #should be used for changing employee info - no password input
  def changeset(employee, attrs, _opts \\ []) do
    IO.puts("employee changeset")
    employee
    |> cast(attrs, [:email, :last_name, :first_name, :role, :hashed_password,  :organization_id])
    |> validate_required([:organization_id])
    |> validate_email()
    # |> validate_password(opts)
    # |> hash_password(opts)
  end

  def registration_changeset(employee, attrs, _opts \\ []) do
    IO.puts("employee.ex employee registration_changeset")
    IO.inspect(attrs)
    employee
    |> cast(attrs, [:email, :password, :last_name, :first_name, :role,:organization_id])
    |> validate_required([:organization_id])
    |> validate_email()
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
    # IO.inspect("PW", password)
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
