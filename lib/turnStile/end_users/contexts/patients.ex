defmodule TurnStile.Patients do
  @moduledoc """
  The Patients context.
  """

  import Ecto.Query, warn: false
  alias TurnStile.Repo
  alias TurnStile.Patients.User
  alias TurnStile.Roles.Role
  alias TurnStile.Roles

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  def list_active_users(organization_id) do
    q =
      from(u in User,
        where: u.organization_id == ^organization_id,
        where: u.is_active? == true,
        preload: [:employee, :organization],
        order_by: [desc: u.inserted_at]
      )
    Repo.all(q)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
   Repo.get!(User, id) |> Repo.preload([:employee, :organization])
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  create_user_w_assocs
    handles the one-many for new user-to-employee
  -needs organization struct OR current_organization_login_id
  -needs to check employee role is valid and sufficient
  """
  def create_user_w_assocs(
        employee_struct,
        user_params,
        org_employee_role,
        organization_struct \\ nil
      ) do
    # IO.inspect(org_employee_role, label: "org_employee_role")

    # IO.inspect(TurnStile.Roles.check_role_has_employee_org_assoc(employee_struct.id, organization_struct.id, role), label: "check_role_has_employee_org_assoc")

    #  IO.inspect(Roles.has, label: "JHERE")

    # IO.inspect(user_params, label: "user_params")
    IO.inspect("organization_struct")
    IO.inspect(organization_struct)
    # build user struct from map
    user = %User{
      first_name: user_params["first_name"] || user_params.first_name,
      last_name: user_params["last_name"] || user_params.last_name,
      email: user_params["email"] || user_params.email,
      phone: user_params["phone"] || user_params.phone,
      health_card_num:
        TurnStile.Utils.convert_to_int(user_params["health_card_num"]) ||
          TurnStile.Utils.convert_to_int(user_params.health_card_num)
    }

    # IO.inspect(employee_struct, label: "employee_struct22")
    # organization = TurnStile.Organizations.get_organization!(user_params["organization_id"] || user_params.organization_id)
    # IO.inspect(user, label: "user")

    # add employee assoc
    user_struct = Ecto.build_assoc(employee_struct, :users, user)
    # add organization assoc
    case employee_struct.current_organization_login_id do
      # if no logged-in user
      nil ->
        case organization_struct do
          nil ->
            error =
              "Error: create_user_w_assocs: Patient.organization struct cannot be nil w/o logged-in user. Organization is required."

            IO.puts(error)
            {:error, error}

          _ ->
            case TurnStile.Roles.check_role_has_employee_org_assoc(
                   employee_struct.id,
                   organization_struct.id,
                   org_employee_role
                 ) do
              {:error, error} ->
                IO.puts(error)
                {:error, error}

              {:ok, _} ->
                if Roles.role_value_has_add_user?(org_employee_role) do
                  # add org assoc
                  user_struct = Ecto.build_assoc(organization_struct, :users, user_struct)
                  # IO.inspect(user_struct, label: "user struct123")
                  {:ok, user_struct}
                else
                  {:error, "Employee lacks permissions to add users"}
                end
            end

            # end
        end

      # if logged-in user
      _ ->
        organization_id = employee_struct.current_organization_login_id
        if Roles.role_value_has_add_user?(org_employee_role) do
          organization_struct = TurnStile.Company.get_organization(organization_id)
          user_struct = Ecto.build_assoc(organization_struct, :users, organization_struct)
          # IO.inspect(user_struct, label: "organization struct123")
          {:ok, user_struct}
        else
          {:error, "Employee lacks permissions to add users"}
        end
    end
  end

  def insert_user(user) do
    case Repo.insert(user) do
      {:ok, user} ->
        {:ok,
         user
         |> Repo.preload(:employee)
         |> Repo.preload(:organization)
         |> Repo.preload(:alerts)}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def deactivate_user(%User{} = user) do
    IO.inspect(user, label: "user")
    # new_user = change_user(user, %{is_active?: false})
    {:ok, new_user} = update_user(user, %{is_active?: false})
    IO.inspect(new_user, label: "new_user")
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
