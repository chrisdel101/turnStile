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

      iex> get_employee_by_email("foo@example.com")
      %Employee{}

      iex> get_employee_by_email("unknown@example.com")
      nil

  """
  def get_employee_by_email(email) when is_binary(email) do
    Repo.get_by(Employee, email: email)
  end

  @doc """
  Gets a employee by email and password.

  ## Examples

      iex> get_employee_by_email_and_password("foo@example.com", "correct_password")
      %Employee{}

      iex> get_employee_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_employee_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    employee = Repo.get_by(Employee, email: email)
    if Employee.valid_password?(employee, password), do: employee
  end

  @doc """
  Gets a single employee.

  Raises `Ecto.NoResultsError` if the Employee does not exist.

  ## Examples

      iex> get_employee!(123)
      %Employee{}

      iex> get_employee!(456)
      ** (Ecto.NoResultsError)

  """
  def get_employee!(id), do: Repo.get!(Employee, id)

  ## Employee registration

  @doc """
  Registers a employee.

  ## Examples

      iex> register_employee(%{field: value})
      {:ok, %Employee{}}

      iex> register_employee(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_employee(attrs) do
    %Employee{}
    |> Employee.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking employee changes.
  Used to create new employees via register

  ## Examples

      iex> use_employee_registration(employee)
      %Ecto.Changeset{data: %Employee{}}

  """
  def use_employee_registration(%Employee{} = employee, attrs \\ %{}) do
    Employee.registration_changeset(employee, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the employee email.

  ## Examples

      iex> change_employee_email(employee)
      %Ecto.Changeset{data: %Employee{}}

  """
  def change_employee_email(employee, attrs \\ %{}) do
    Employee.email_changeset(employee, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_employee_email(employee, "valid password", %{email: ...})
      {:ok, %Employee{}}

      iex> apply_employee_email(employee, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_employee_email(employee, password, attrs) do
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
  def update_employee_email(employee, token) do
    context = "change:#{employee.email}"

    with {:ok, query} <- EmployeeToken.verify_change_email_token_query(token, context),
         %EmployeeToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(employee_email_multi(employee, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp employee_email_multi(employee, email, context) do
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

      iex> deliver_update_email_instructions(employee, current_email, &Routes.employee_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%Employee{} = employee, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, employee_token} = EmployeeToken.build_email_token(employee, "change:#{current_email}")

    Repo.insert!(employee_token)
    EmployeeNotifier.deliver_update_email_instructions(employee, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the employee password.

  ## Examples

      iex> change_employee_password(employee)
      %Ecto.Changeset{data: %Employee{}}

  """
  def change_employee_password(employee, attrs \\ %{}) do
    Employee.password_changeset(employee, attrs, hash_password: false)
  end

  @doc """
  Updates the employee password.

  ## Examples

      iex> update_employee_password(employee, "valid password", %{password: ...})
      {:ok, %Employee{}}

      iex> update_employee_password(employee, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_employee_password(employee, password, attrs) do
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
  def generate_employee_session_token(employee) do
    {token, employee_token} = EmployeeToken.build_session_token(employee)
    Repo.insert!(employee_token)
    token
  end

  @doc """
  Gets the employee with the given signed token.
  """
  def get_employee_by_session_token(token) do
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

      iex> deliver_employee_confirmation_instructions(employee, &Routes.employee_confirmation_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_employee_confirmation_instructions(confirmed_employee, &Routes.employee_confirmation_url(conn, :edit, &1))
      {:error, :already_confirmed}

  """
  def deliver_employee_confirmation_instructions(%Employee{} = employee, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if employee.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, employee_token} = EmployeeToken.build_email_token(employee, "confirm")
      Repo.insert!(employee_token)
      EmployeeNotifier.deliver_confirmation_instructions(employee, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a employee by the given token.

  If the token matches, the employee account is marked as confirmed
  and the token is deleted.
  """
  def confirm_employee(token) do
    with {:ok, query} <- EmployeeToken.verify_email_token_query(token, "confirm"),
         %Employee{} = employee <- Repo.one(query),
         {:ok, %{employee: employee}} <- Repo.transaction(confirm_employee_multi(employee)) do
      {:ok, employee}
    else
      _ -> :error
    end
  end

  defp confirm_employee_multi(employee) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:employee, Employee.confirm_changeset(employee))
    |> Ecto.Multi.delete_all(:tokens, EmployeeToken.employee_and_contexts_query(employee, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given employee.

  ## Examples

      iex> deliver_employee_reset_password_instructions(employee, &Routes.employee_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_employee_reset_password_instructions(%Employee{} = employee, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, employee_token} = EmployeeToken.build_email_token(employee, "reset_password")
    Repo.insert!(employee_token)
    EmployeeNotifier.deliver_reset_password_instructions(employee, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the employee by reset password token.

  ## Examples

      iex> get_employee_by_reset_password_token("validtoken")
      %Employee{}

      iex> get_employee_by_reset_password_token("invalidtoken")
      nil

  """
  def get_employee_by_reset_password_token(token) do
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

      iex> reset_employee_password(employee, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Employee{}}

      iex> reset_employee_password(employee, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_employee_password(employee, attrs) do
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

      iex> list_all_employees()
      [%Employee{}, ...]

  """
  def list_all_employees do
    # query all
    query = from(a in Employee, select: a)
    Repo.all(query)
  end

  def list_employees_by_organization(organization_id) do
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

      iex> get_employee!(123)
      %Employee{}

  """
  def get_employee!(id), do: raise "TODO"

  @doc """
  Creates a employee.

  ## Examples

      iex> create_employee(%{field: value})
      {:ok, %Employee{}}

      iex> create_employee(%{field: bad_value})
      {:error, ...}

  """
  def create_employee(%Employee{} = employee, attrs \\ %{}) do
    Employee.changeset(employee, attrs)
  end


  @doc """
  Updates a employee.

  ## Examples

      iex> update_employee(employee, %{field: new_value})
      {:ok, %Employee{}}

      iex> update_employee(employee, %{field: bad_value})
      {:error, ...}

  """
  def update_employee(%Employee{} = employee, attrs) do
    IO.inspect(attrs)
    changeset = change_employee(employee)
    IO.inspect(changeset)
  end

  @doc """
  Deletes a Employee.

  ## Examples

      iex> delete_employee(employee)
      {:ok, %Employee{}}

      iex> delete_employee(employee)
      {:error, ...}

  """
  def delete_employee(%Employee{} = employee) do
    raise "TODO"
  end

  @doc """
  Returns a data structure for tracking employee changes.

  ## Examples

      iex> change_employee(employee)
      %Todo{...}

  """
  def change_employee(%Employee{} = employee, attrs \\ %{}) do
    Employee.changeset(employee, attrs)
  end

  def check_employee_is_in_organization(employee, organization_id) do
    organization = Company.get_organization(organization_id)
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
