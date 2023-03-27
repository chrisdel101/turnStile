defmodule TurnStile.Staff do
  @moduledoc """
  The Staff context.
  """

  import Ecto.Query, only: [from: 2], warn: false
  alias TurnStile.Repo
  alias TurnStile.Company
  alias TurnStile.Staff.{Employee, EmployeeToken, EmployeeNotifier}

  ## Database getters

  @doc """
  Gets a employee by email.

  ## Examples

      iex> get_admin_by_email("foo@example.com")
      %Employee{}

      iex> get_admin_by_email("unknown@example.com")
      nil

  """
  def get_admin_by_email(email) when is_binary(email) do
    Repo.get_by(Employee, email: email)
  end

  @doc """
  Gets a employee by email and password.

  ## Examples

      iex> get_admin_by_email_and_password("foo@example.com", "correct_password")
      %Employee{}

      iex> get_admin_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_admin_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    employee = Repo.get_by(Employee, email: email)
    if Employee.valid_password?(employee, password), do: employee
  end

  @doc """
  Gets a single employee.

  Raises `Ecto.NoResultsError` if the Employee does not exist.

  ## Examples

      iex> get_admin!(123)
      %Employee{}

      iex> get_admin!(456)
      ** (Ecto.NoResultsError)

  """
  def get_admin!(id), do: Repo.get!(Employee, id)

  ## Employee registration

  @doc """
  Registers a employee.

  ## Examples

      iex> register_admin(%{field: value})
      {:ok, %Employee{}}

      iex> register_admin(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_admin(attrs) do
    %Employee{}
    |> Employee.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking employee changes.

  ## Examples

      iex> change_admin_registration(employee)
      %Ecto.Changeset{data: %Employee{}}

  """
  def change_admin_registration(%Employee{} = employee, attrs \\ %{}) do
    Employee.registration_changeset(employee, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the employee email.

  ## Examples

      iex> change_admin_email(employee)
      %Ecto.Changeset{data: %Employee{}}

  """
  def change_admin_email(employee, attrs \\ %{}) do
    Employee.email_changeset(employee, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_admin_email(employee, "valid password", %{email: ...})
      {:ok, %Employee{}}

      iex> apply_admin_email(employee, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_admin_email(employee, password, attrs) do
    employee
    |> Employee.email_changeset(attrs)
    |> Employee.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the employee email using the given token.

  If the token matches, the employee email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_admin_email(employee, token) do
    context = "change:#{employee.email}"

    with {:ok, query} <- EmployeeToken.verify_change_email_token_query(token, context),
         %EmployeeToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(admin_email_multi(employee, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp admin_email_multi(employee, email, context) do
    changeset =
      employee
      |> Employee.email_changeset(%{email: email})
      |> Employee.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:employee, changeset)
    |> Ecto.Multi.delete_all(:tokens, EmployeeToken.employee_and_contexts_query(employee, [context]))
  end

  @doc """
  Delivers the update email instructions to the given employee.

  ## Examples

      iex> deliver_update_email_instructions(employee, current_email, &Routes.admin_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%Employee{} = employee, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, admin_token} = EmployeeToken.build_email_token(employee, "change:#{current_email}")

    Repo.insert!(admin_token)
    EmployeeNotifier.deliver_update_email_instructions(employee, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the employee password.

  ## Examples

      iex> change_admin_password(employee)
      %Ecto.Changeset{data: %Employee{}}

  """
  def change_admin_password(employee, attrs \\ %{}) do
    Employee.password_changeset(employee, attrs, hash_password: false)
  end

  @doc """
  Updates the employee password.

  ## Examples

      iex> update_admin_password(employee, "valid password", %{password: ...})
      {:ok, %Employee{}}

      iex> update_admin_password(employee, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_admin_password(employee, password, attrs) do
    changeset =
      employee
      |> Employee.password_changeset(attrs)
      |> Employee.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:employee, changeset)
    |> Ecto.Multi.delete_all(:tokens, EmployeeToken.employee_and_contexts_query(employee, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{employee: employee}} -> {:ok, employee}
      {:error, :employee, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_admin_session_token(employee) do
    {token, admin_token} = EmployeeToken.build_session_token(employee)
    Repo.insert!(admin_token)
    token
  end

  @doc """
  Gets the employee with the given signed token.
  """
  def get_admin_by_session_token(token) do
    {:ok, query} = EmployeeToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(EmployeeToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given employee.

  ## Examples

      iex> deliver_admin_confirmation_instructions(employee, &Routes.admin_confirmation_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_admin_confirmation_instructions(confirmed_admin, &Routes.admin_confirmation_url(conn, :edit, &1))
      {:error, :already_confirmed}

  """
  def deliver_admin_confirmation_instructions(%Employee{} = employee, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if employee.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, admin_token} = EmployeeToken.build_email_token(employee, "confirm")
      Repo.insert!(admin_token)
      EmployeeNotifier.deliver_confirmation_instructions(employee, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a employee by the given token.

  If the token matches, the employee account is marked as confirmed
  and the token is deleted.
  """
  def confirm_admin(token) do
    with {:ok, query} <- EmployeeToken.verify_email_token_query(token, "confirm"),
         %Employee{} = employee <- Repo.one(query),
         {:ok, %{employee: employee}} <- Repo.transaction(confirm_admin_multi(employee)) do
      {:ok, employee}
    else
      _ -> :error
    end
  end

  defp confirm_admin_multi(employee) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:employee, Employee.confirm_changeset(employee))
    |> Ecto.Multi.delete_all(:tokens, EmployeeToken.employee_and_contexts_query(employee, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given employee.

  ## Examples

      iex> deliver_admin_reset_password_instructions(employee, &Routes.admin_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_admin_reset_password_instructions(%Employee{} = employee, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, admin_token} = EmployeeToken.build_email_token(employee, "reset_password")
    Repo.insert!(admin_token)
    EmployeeNotifier.deliver_reset_password_instructions(employee, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the employee by reset password token.

  ## Examples

      iex> get_admin_by_reset_password_token("validtoken")
      %Employee{}

      iex> get_admin_by_reset_password_token("invalidtoken")
      nil

  """
  def get_admin_by_reset_password_token(token) do
    with {:ok, query} <- EmployeeToken.verify_email_token_query(token, "reset_password"),
         %Employee{} = employee <- Repo.one(query) do
      employee
    else
      _ -> nil
    end
  end

  @doc """
  Resets the employee password.

  ## Examples

      iex> reset_admin_password(employee, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Employee{}}

      iex> reset_admin_password(employee, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_admin_password(employee, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:employee, Employee.password_changeset(employee, attrs))
    |> Ecto.Multi.delete_all(:tokens, EmployeeToken.employee_and_contexts_query(employee, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{employee: employee}} -> {:ok, employee}
      {:error, :employee, changeset, _} -> {:error, changeset}
    end
  end

  alias TurnStile.Staff.Employee

  @doc """
  Returns the list of employees.

  ## Examples

      iex> list_all_admins()
      [%Employee{}, ...]

  """
  def list_all_admins do
    # query all
    query = from(a in Employee, select: a)
    Repo.all(query)
  end

  def list_admins_by_organization(organization_id) do
    # IO.inspect(organization_id)
    q = from a in Employee,
    where: a.organization_id == ^organization_id,
    select: a
    Repo.all(q)
  end

  @doc """
  Gets a single employee.

  Raises if the Employee does not exist.

  ## Examples

      iex> get_admin!(123)
      %Employee{}

  """
  def get_admin!(id), do: raise "TODO"

  @doc """
  Creates a employee.

  ## Examples

      iex> create_admin(%{field: value})
      {:ok, %Employee{}}

      iex> create_admin(%{field: bad_value})
      {:error, ...}

  """
  def create_admin(%Employee{} = employee, attrs \\ %{}) do
    Employee.changeset(employee, attrs)
  end


  @doc """
  Updates a employee.

  ## Examples

      iex> update_admin(employee, %{field: new_value})
      {:ok, %Employee{}}

      iex> update_admin(employee, %{field: bad_value})
      {:error, ...}

  """
  def update_admin(%Employee{} = employee, attrs) do
    raise "TODO"
  end

  @doc """
  Deletes a Employee.

  ## Examples

      iex> delete_admin(employee)
      {:ok, %Employee{}}

      iex> delete_admin(employee)
      {:error, ...}

  """
  def delete_admin(%Employee{} = employee) do
    raise "TODO"
  end

  @doc """
  Returns a data structure for tracking employee changes.

  ## Examples

      iex> change_admin(employee)
      %Todo{...}

  """
  def change_admin(%Employee{} = employee, attrs \\ %{}) do
    Employee.changeset(employee, attrs)
  end

  def check_admin_is_in_organization(employee, organization_id) do
    organization = Company.get_organization(organization_id)
    IO.inspect("check_admin_is_in_organization")

    if organization do
      if organization.id == employee.organization_id do
        true
      else
        false
      end
    else
      false
    end
  end
end
