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
    Repo.get(Role, id) |> Repo.preload([:employee, :organization])
  end

  # get employee role within an organization
  def get_employee_role_in_organization(employee_id, organization_id) do
    if is_nil(employee_id) || is_nil(organization_id) do
      IO.puts("get_employee_role_in_organization: nil input")
      nil
    else
      q =
        from(r in Role,
          where: r.employee_id == ^employee_id,
          where: r.organization_id == ^organization_id,
          preload: [:employee, :organization]
        )

      Repo.one(q)
    end
  end

  @doc """
  """
  def role_exists?(role), do: !is_nil(role)

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
          case Repo.insert(role) do
            {:ok, role} ->
              {:ok,
               role
               |> Repo.preload(:employee)
               |> Repo.preload(:organization)}

            {:error, error} ->
              {:error, error}
          end

        {:error, error} ->
          {:error, error}
      end
    end
  end

  # confirm that both struct items are on the role
  # confirm that both stuct items are the the correct ones for this role
  #  - should be the same a Staff.check_employee_matches_organization
  # - specfically called on a role here
  def check_role_has_employee_org_assoc(employee_id, organization_id, role) do
    # IO.inspect(role, label: "Role")
    # IO.inspect(employee_id, label: "employee_id")
    # IO.inspect(organization_id, label: "organization_id")
    #  check ids match assocs; checks for invalid empl and orgs this way;
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

  # confirm prev emp/org assoc hold
  # confirm user is
  # params are extracted and used
  def check_role_has_employee_org_asocc_and_user_org_assoc(
        employee_id,
        organization_id,
        user_struct,
        role
      ) do
    # IO.inspect(user_struct, label: "user_struct")
    case check_role_has_employee_org_assoc(employee_id, organization_id, role) do
      {:ok, _} ->
        {:ok, true}

      # make sure user is associated with organization
      cond do
        !Ecto.assoc_loaded?(user_struct.organization) ->
          error =
            "Error: Roles.check_role_has_employee_org_asocc_and_user_org_assoc user organization is not loaded"

          # IO.puts(error)
          {:error, error}

        user_struct.organization.id !== organization_id ->
          error =
            "Error: Roles.check_role_has_employee_org_asocc_and_user_org_assoc user organization id does not match"

          # IO.puts(error)
          {:error, error}

        true ->
          {:ok, true}
      end

      {:error, error} ->
        {:error, error}
    end
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

  # checks permissions for a role; rather than checking employee directly
  # - used in business logic w no req.res
  def role_has_add_user_permission?(role_struct) do
    role_value = role_struct.value

    if TurnStile.Utils.convert_to_int(role_value) <=
         EmployeePermissionThresholds.add_user_permissions_threshold() do
      true
    else
      false
    end
  end

  def role_has_send_alert_permission?(role_struct) do
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
