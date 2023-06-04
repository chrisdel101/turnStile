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
    employee = Repo.get_by(Employee, email: email) |> Repo.preload(:roles)
    if Employee.valid_password?(employee, password), do: employee
  end

  @doc """
  Gets a single employee.


  ## Examples

      iex> get_employee(123)
      %Employee{}

      iex> get_employee(456)
      ** (Ecto.NoResultsError)

  """
  def get_employee(id), do: Repo.get(Employee, id) |> Repo.preload(:roles)

  @doc """
  Gets role on current organization.

  """

  def get_organization_role(employee, organization_id) do
    if is_nil(employee) || is_nil(organization_id) do
      IO.puts("get_organization_role: nil input")
      nil
    else
      q =
        from r in TurnStile.Role,
          where: r.organization_id == ^organization_id,
          where: r.employee_id == ^employee.id,
          select: r

      Repo.one(q)
    end
  end

  ## Employee registration

  @doc """
  # Registers a employee assocaited with organizatio and role

  """
  def register_and_preload_employee(attrs, organization) do
    # https://elixirforum.com/t/confussed-with-build-assoc-vs-put-assoc-vs-cast-assoc/29116
    role_name = attrs["role"] || attrs.role
    # build a Role
    role = %TurnStile.Role{
      name: role_name,
      value: to_string(EmployeePermissionGroups.get_persmission_value(role_name))
    }

    # assoc role with organization
    role = Ecto.build_assoc(organization, :roles, role)
    # build employee and assoc the role
    emp_changeset =
      %Employee{}
      |> Employee.registration_changeset(attrs)
      |> Ecto.Changeset.put_assoc(:roles, [role])

    # Repo.transaction(fn ->
    # insert employee - auto insert role using associations``
    case Repo.insert(emp_changeset) do
      {:ok, new_emp} ->
        emp_preload =
          Repo.preload(new_emp, :organizations)
          |> Repo.preload(:roles)

        {:ok, emp_preload}

      {:error, error} ->
        {:error, error}
    end

    #   Repo.rollback({:rolling})
    # end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking employee registration changes.
  Used to change employees via register.
  - hash_password: false


  ## Examples

      iex> change_employee_registration(employee)
      %Ecto.Changeset{data: %Employee{}}

  """
  def change_employee_registration(%Employee{} = employee, attrs \\ %{}) do
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
    |> Ecto.Multi.delete_all(
      :tokens,
      EmployeeToken.employee_and_contexts_query(employee, [context])
    )
  end

  @doc """
  Delivers the update email instructions to the given employee.

  ## Examples

      iex> deliver_update_email_instructions(employee, current_email, &Routes.employee_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(
        %Employee{} = employee,
        current_email,
        update_email_url_fun
      )
      when is_function(update_email_url_fun, 1) do
    {encoded_token, employee_token} =
      EmployeeToken.build_email_token(employee, "change:#{current_email}")

    Repo.insert!(employee_token)

    EmployeeNotifier.deliver_update_email_instructions(
      employee,
      update_email_url_fun.(encoded_token)
    )
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

      EmployeeNotifier.deliver_confirmation_instructions(
        employee,
        confirmation_url_fun.(encoded_token)
      )
    end
  end

  @doc """
  Delivers the welcome email. Use when EMPLOYEE_CREATE_CONFIRM_IS_REQUIRED != "true"

  """
  def deliver_employee_welcome_email(%Employee{} = employee) do
    EmployeeNotifier.deliver_welcome_email_instructions(employee)
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
    |> Ecto.Multi.delete_all(
      :tokens,
      EmployeeToken.employee_and_contexts_query(employee, ["confirm"])
    )
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

    EmployeeNotifier.deliver_reset_password_instructions(
      employee,
      reset_password_url_fun.(encoded_token)
    )
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

  @doc """
  Return all employees list that are assoc with an organization .

  ## Examples

      iex> list_employee_ids_by_organization(org_id)
      [...]

  """
  def list_employee_ids_by_organization(organization_id) do
    if not is_nil(organization_id) do
      q =
        from o in "organization_employees",
          join: o1 in "organizations",
          on: o.organization_id == o1.id,
          join: e in "employees",
          on: o.employee_id == e.id,
          where: o1.id == ^organization_id,
          select: e.id

      Repo.all(q)
    else
      []
    end
  end

  @doc """
  Find all ids in employees table and return list of employees.

  ## Examples

      iex> list_employees_by_ids(ids)
      [...]

  """
  def list_employees_by_ids(ids) do
    if not is_nil(ids) do
      q =
        from e in Employee,
          where: e.id in ^ids,
          select: e

      Repo.all(q) |> Repo.preload(:roles)
    else
      []
    end
  end

  @doc """
  Creates a employee.

  ## Examples

      iex> create_employee(%{field: value})
      {:ok, %Employee{}}

      iex> create_employee(%{field: bad_value})
      {:error, ...}

  """
  def create_employee(%Employee{} = employee, attrs \\ %{}) do
    Employee.creation_form_changeset(employee, attrs)
  end

  @doc """
  Updates a employee. Used changeset with no validations

  ## Examples

      iex> update_employee(employee, %{field: new_value})
      {:ok, %Employee{}}

      iex> update_employee(employee, %{field: bad_value})
      {:error, ...}

  """
  def update_employee(%Employee{} = employee, attrs) do
    employee
    |> Employee.changeset(attrs)
    |> Repo.update()
  end

  def update_employee(employee) do
    u_employee = Ecto.Changeset.change(employee)
    Repo.update(u_employee)
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
    Employee.changeset(employee, attrs, hashed_password: false)
  end

  @doc """
  Checks if there is entry with both org_id and employee_id. Returns id of entry row, else nil

  ## Examples

      iex> change_employee(employee)
      %Todo{...}

  """
  def check_employee_is_in_organization(employee, organization_id) do
    if !is_nil(organization_id) && !is_nil(employee) do
      organization_id = TurnStile.Utils.convert_to_int(organization_id)
      organization = Company.get_organization(organization_id)

      employee_id =
        TurnStile.Utils.convert_to_int(Map.get(employee, :id) || Map.get(employee, "id"))

      if organization do
        q =
          from o in "organization_employees",
            where: o.employee_id == ^employee_id and o.organization_id == ^organization_id,
            select: o.id

        Repo.one(q)
      end
    else
      IO.inspect("Error in check_employee_is_in_organization. Inputs are nil")
      nil
    end
  end

  # sets the role fields when employee is logged in
  def set_employee_role(employee, organization_id) do
    # IO.inspect(employee)
    # IO.inspect(organization_id)
    role = get_organization_role(employee, organization_id)
    # IO.inspect(role)
    # IO.inspect(role.name)
    # enum types need ints as strings
    change_params = %{
      role_on_current_organization: role.name,
      role_value_on_current_organization: to_string(role.value),
      current_organization_login_id: organization_id
    }

    # IO.inspect("PPPPP")
    # IO.inspect(change_params)
    changeset = change_employee(employee, change_params)
    # IO.inspect("QQQQ")
    # IO.inspect(changeset)

    case Repo.update(changeset) do
      {:ok, update_emp} ->
        # IO.inspect("ADASDSAD")
        # IO.inspect(update_emp)
        {:ok, update_emp}
      {:error, error} ->
        {:error, error}
    end
  end

  # sets the role fields when employee is logged in
  def unset_employee_role(employee) do
    change_params = %{
      role_value_on_current_organization: nil,
      current_organization_login_id: nil
    }

    changeset = change_employee(employee, change_params)
    Repo.update(changeset)
  end

  # sets is_logged_in? employee flag to true
  def set_is_logged_in(employee) do
    change_employee(employee, %{is_logged_in?: true})
    |> Repo.update()
  end

  # sets is_logged_in? employee flag to false
  def unset_is_logged_in(employee) do
    change_employee(employee, %{is_logged_in?: false})
    |> Repo.update()
  end

  alias TurnStile.Staff.Owner

  @doc """
  Returns the list of owners.

  ## Examples

      iex> list_owners()
      [%Owner{}, ...]

  """
  def list_owners do
    Repo.all(Owner)
  end

  @doc """
  Gets a single owner.

  Raises `Ecto.NoResultsError` if the Owner does not exist.

  ## Examples

      iex> get_owner!(123)
      %Owner{}

      iex> get_owner!(456)
      ** (Ecto.NoResultsError)

  """
  def get_owner!(id), do: Repo.get!(Owner, id)

  @doc """
  Creates a owner.

  ## Examples

      iex> create_owner(%{field: value})
      {:ok, %Owner{}}

      iex> create_owner(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_owner(attrs \\ %{}) do
    %Owner{}
    |> Owner.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a owner.

  ## Examples

      iex> update_owner(owner, %{field: new_value})
      {:ok, %Owner{}}

      iex> update_owner(owner, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_owner(%Owner{} = owner, attrs) do
    owner
    |> Owner.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a owner.

  ## Examples

      iex> delete_owner(owner)
      {:ok, %Owner{}}

      iex> delete_owner(owner)
      {:error, %Ecto.Changeset{}}

  """
  def delete_owner(%Owner{} = owner) do
    Repo.delete(owner)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking owner changes.

  ## Examples

      iex> change_owner(owner)
      %Ecto.Changeset{data: %Owner{}}

  """
  def change_owner(%Owner{} = owner, attrs \\ %{}) do
    Owner.changeset(owner, attrs)
  end
end
