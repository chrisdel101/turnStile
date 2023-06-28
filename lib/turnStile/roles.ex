defmodule TurnStile.Roles do
  @moduledoc """
  The Roles context.
  """

  import Ecto.Query, warn: false
  alias TurnStile.Repo

  alias TurnStile.Roles.Role

  @doc """
  Returns the list of roles.

  ## Examples

      iex> list_roles()
      [%Role{}, ...]

  """
  def list_roles do
    raise "TODO"
  end

  @doc """
  Gets a single role.

  Raises if the Role does not exist.

  ## Examples

      iex> get_role!(123)
      %Role{}

  """
  def get_role(id) do
    Repo.get(Role, id)
  end

  @doc """
  Creates a role.

  ## Examples

      iex> create_role(%{field: value})
      {:ok, %Role{}}

      iex> create_role(%{field: bad_value})
      {:error, ...}

  """
  def create_role(%Role{} = role, attrs \\ %{}) do
    Role.changeset(role, attrs)
  end

  def build_role(attrs) do
    %Role{
      name: attrs[:name] || attrs["name"],
      value: attrs[:value] || attrs["value"]
    }
  end

  def assocaiate_role_with_employee(role, employee) do
    employee
    |> Ecto.build_assoc(:roles, role)
    |> Repo.preload(:employee)
  end

  def assocaiate_role_with_organization(role, organization) do
    organization
    |> Ecto.build_assoc(:roles, role)
    |> Repo.preload(:organization)
  end

  # employee can have only 1 role per organization
  def insert_role(employee_id, organization_id, role) do
    if organization_employee_role_exists?(employee_id, organization_id) do
      {:error, "Role already exists"}
    else
      case check_role_has_employee_org_assoc(employee_id, organization_id, role) do
        {:ok, true} ->
          Repo.insert(role)

        {:error, error} ->
          {:error, error}
      end
    end
  end

  # confirm that both struct items are on the role
  # confirm that both stuct items are the the correct ones for this role
  def check_role_has_employee_org_assoc(employee_id, organization_id, role) do
    #  check ids match assocs; checks for invalid empl and orgs this way
    cond do
      # confirm employee preload
      !Ecto.assoc_loaded?(role.employee) ->
        error = "Error: Roles.validate_insert_role employee assoc is not loaded"
        IO.puts(error)
        {:error, error}

      # confirm org preload
      !Ecto.assoc_loaded?(role.organization) ->
        error = "Error: Roles.validate_insert_role organization assoc is not loaded"
        IO.puts(error)
        {:error, error}

      # confirm employee id matches preload
      role.employee.id !== employee_id ->
        error = "Error: Roles.validate_insert_role employee_id does not match role.employee.id"
        IO.puts(error)
        {:error, error}

      # confirm org id matches preload
      role.organization.id !== organization_id ->
        error =
          "Error: Roles.validate_insert_role organization_id does not match role.organization.id"

        IO.puts(error)
        {:error, error}

      true ->
        {:ok, true}
    end
  end
  # confirm that both struct items are on the role
  # confirm that both stuct items are the the correct ones for this role
  # third param (assoc_check_function) is a function call to
  # params are extracted and used
  def check_role_has_employee_org_user_assoc(user_id, assoc_check_function)
    when is_function(assoc_check_function) do
      {employee_id, organization_id, role} = assoc_check_function
      case assoc_check_function do
        {:ok, true} ->
          "hello"
          # cond do

          # end

        {:error, error} ->
          {:error, error}
      end
    # else
    #   {:error, "third param must be a function call"}
end

  # check for role with both org & employee
  def organization_employee_role_exists?(employee_id, organization_id) do
    if not is_nil(employee_id) and not is_nil(organization_id) do
      if not is_integer(employee_id) || not is_integer(organization_id) do
        IO.puts(
          "Error: Roles.organization_employee_role_exists invalid input. Inputs must be integers"
        )

        false
      else
        q =
          from(r in Role,
            where: r.employee_id == ^employee_id and r.organization_id == ^organization_id
          )

        Repo.exists?(q)
      end
    end
  end

  def role_value_has_add_user?(role_struct) do
    role_value = role_struct.value
    if TurnStile.Utils.convert_to_int(role_value) <=
         EmployeePermissionThresholds.add_user_permissions_threshold() do
      true
    else
      false
    end
  end

  def role_value_has_add_alert?(role_struct) do
    role_value = role_struct.value
    if TurnStile.Utils.convert_to_int(role_value) <=
         EmployeePermissionThresholds.send_alert_permissions_threshold() do
      true
    else
      false
    end
  end

  @doc """
  Updates a role.

  ## Examples

      iex> update_role(role, %{field: new_value})
      {:ok, %Role{}}

      iex> update_role(role, %{field: bad_value})
      {:error, ...}

  """
  def update_role(%Role{} = role, attrs) do
    raise "TODO"
  end

  @doc """
  Deletes a Role.

  ## Examples

      iex> delete_role(role)
      {:ok, %Role{}}

      iex> delete_role(role)
      {:error, ...}

  """
  def delete_role(%Role{} = role) do
    raise "TODO"
  end

  @doc """
  Returns a data structure for tracking role changes.

  ## Examples

      iex> change_role(role)
      %Todo{...}

  """
  def change_role(%Role{} = role, _attrs \\ %{}) do
    raise "TODO"
  end
end
