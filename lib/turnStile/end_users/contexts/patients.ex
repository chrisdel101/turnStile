defmodule TurnStile.Patients do
  @moduledoc """
  The Patients context.
  """

  import Ecto.Query, warn: false
  alias TurnStile.Repo

  alias TurnStile.Patients.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  def list_active_users do
    q = from(u in User,
      where: u.is_active? == true,
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
  def get_user!(id), do: Repo.get!(User, id)

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
# handle the one-many for new user-to-employee on create
  def create_user_w_assocs(employee_struct, user_params, organization_struct \\ nil) do
    # IO.inspect(user_params, label: "user_params")
    # IO.inspect(organization_struct, label: "organization_struct")
    # build user struct from map
    user = %User{
      first_name: user_params["first_name"] || user_params.first_name,
      last_name: user_params["last_name"] || user_params.last_name,
      email: user_params["email"] || user_params.email,
      phone: user_params["phone"] || user_params.phone,
      health_card_num: TurnStile.Utils.convert_to_int(user_params["health_card_num"]) || TurnStile.Utils.convert_to_int(user_params.health_card_num)
    }
    IO.inspect(employee_struct, label: "employee_struct")
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
            error = "Error: create_user_w_assocs: Patient.organization struct cannot be nil w/o logged-in user. Organization is required."
            IO.puts(error)
            {:error, error}
          _ ->
              # add org assoc
            user_struct = Ecto.build_assoc(organization_struct, :users, user_struct)
            {:ok, user_struct}
            # IO.inspect(user_struct, label: "organization struct")
            # insert_user(user_struct)
        end
        # if logged-in user
      _ ->
        organization_id = employee_struct.current_organization_login_id
        organization_struct = TurnStile.Company.get_organization(organization_id)
        user_struct = Ecto.build_assoc(organization_struct, :users, user_struct)
        # IO.inspect(user_struct, label: "organization struct123")
        {:ok, user_struct}
        # insert_user(user_struct)
      end
  end

  def insert_user(user) do
     # user = Ecto.build_assoc(employee_struct, :users, user)
    #  IO.inspect(user, label: "insert_user")
    Repo.insert(user)
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
