defmodule TurnStile.Patients do
  @moduledoc """
  The Patients context.
  """

  import Ecto.Query, warn: false
  alias TurnStile.Patients.UserNotifier
  alias TurnStile.Repo
  alias TurnStile.Patients.User
  alias TurnStile.Patients.UserToken
  alias TurnStile.Roles

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  # ADMIN ONLY function
  def list_all_users do
    Repo.all(User)
  end

  # - lists all users w.in an organization
  def list_users(organization_id) do
    q =
      from(u in User,
        where: u.organization_id == ^organization_id,
        preload: [:employee, :organization],
        order_by: [desc: u.inserted_at]
      )

    Repo.all(q)
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

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      ** (Ecto.NoResultsError)

  """
  def get_user(id) do
   Repo.get(User, id) |> Repo.preload([:employee, :organization])
  end

  # - there could be multiple users w. the same phone so we return a list
  # TODO - make more robust search
  # -needs to check if input number matches also for 1, and +1
  # -need to check if there is match of input w/ a 1 or +1
  def get_users_by_phone(phone) do
    # remove leading 1 and +
    phone = TurnStile.Utils.remove_first_string_char(phone, "+")
    phone = TurnStile.Utils.remove_first_string_char(phone, "1")

    q =
      from(u in User,
        where: u.phone == ^phone,
        order_by: [desc: u.inserted_at],
        preload: [:employee, :organization]
      )
    Repo.all(q)
  end

  def get_user_most_recently_updated(user_list) do
    Enum.reduce(user_list, hd(user_list), fn user, acc ->
      dt1 = DateTime.from_naive!(acc.updated_at, "Etc/UTC")
      dt2 = DateTime.from_naive!(user.updated_at, "Etc/UTC")
      # if DateTime.compare(user.inserted, acc) == :gt, do: val, else: acc
      if DateTime.compare(dt1, dt2) == :gt, do: acc, else: user
    end)
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
    # IO.inspect("organization_struct")
    # IO.inspect(organization_struct)

    # spread the map into the object; check map type first
    user =
      if !TurnStile.Utils.is_arrow_map?(user_params) do
        %User{} |> Map.put_new(:__struct__, User) |> Map.merge(user_params)
      else
        user_params = TurnStile.Utils.convert_arrow_map_to_atom(user_params)
        %User{} |> Map.put_new(:__struct__, User) |> Map.merge(user_params)
      end

    # organization = TurnStile.Organizations.get_organization!(user_params["organization_id"] || user_params.organization_id)
    # IO.inspect(user, label: "user")

    # add employee assoc
    user_struct = Ecto.build_assoc(employee_struct, :users, user)
    # IO.inspect(user_struct, label: "user")
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
                if Roles.role_has_add_user_permission?(org_employee_role) do
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

        if Roles.role_has_add_user_permission?(org_employee_role) do
          organization_struct = TurnStile.Company.get_organization(organization_id)
          user_struct = Ecto.build_assoc(organization_struct, :users, user_struct)
          IO.inspect(user_struct, label: "organization struct123")
          {:ok, user_struct}
        else
          {:error, "Employee lacks permissions to add users"}
        end
    end
  end

  # - add 2 to name to seperate from other version; param errors
  # - eventually remove old version; used in seeds now
  def create_user_w_assocs2(
        employee_struct,
        user_params,
        organization_struct \\ nil
      ) do
    # spread the map into the object; check map type first
    user =
      if !TurnStile.Utils.is_arrow_map?(user_params) do
        %User{} |> Map.put_new(:__struct__, User) |> Map.merge(user_params)
      else
        user_params = TurnStile.Utils.convert_arrow_map_to_atom(user_params)
        %User{} |> Map.put_new(:__struct__, User) |> Map.merge(user_params)
      end

    # add employee assoc
    user_struct = Ecto.build_assoc(employee_struct, :users, user)

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
            user_struct = Ecto.build_assoc(organization_struct, :users, user_struct)
            # IO.inspect(user_struct, label: "user struct123")
            {:ok, user_struct}
        end

      # if logged-in user
      _ ->
        organization_id = employee_struct.current_organization_login_id

        organization_struct = TurnStile.Company.get_organization(organization_id)
        user_struct = Ecto.build_assoc(organization_struct, :users, user_struct)
        IO.inspect(user_struct, label: "organization struct123")
        {:ok, user_struct}
    end
  end

  def insert_user(user) do
    # convert val to int
    user = Map.put(user, :health_card_num, TurnStile.Utils.convert_to_int(user.health_card_num))

    case Repo.insert(user) do
      {:ok, user} ->
        {:ok,
         user
         |> Repo.preload([:employee, :organization])}

      {:error, error} ->
        {:error, error}
    end
  end

  def user_assoc_in_organization?(user_struct, organization_id) do
    # # make sure user is associated with organization
    cond do
      !Ecto.assoc_loaded?(user_struct.organization) ->
        error = "Error: Roles.check_role_has_user_org_assoc user organization is not loaded"

        # IO.puts(error)
        {:error, error}

      user_struct.organization.id !== organization_id ->
        error = "Error: Roles.check_role_has_user_org_assoc user organization id does not match"

        # IO.puts(error)
        {:error, error}

      true ->
        {:ok, true}
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
    IO.inspect(attrs, label: "attrs")
    changeset =
      user
    |> User.changeset(attrs)
    case Repo.update(changeset) do
      {:ok, user} ->
        {:ok,
         user
         |> Repo.preload([:employee, :organization])}

      {:error, error} ->
        {:error, error}
    end
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

  #  NO preloading - may cause error later
  def update_alert_status(user, new_alert_status) do
    # {:error, "Error: update_alert_status: invalid alert status type"}
    if Enum.member?(
         UserAlertStatusTypesMap.get_user_statuses_enum(),
         String.to_atom(new_alert_status)
       ) do
       update_user(user, %{user_alert_status: new_alert_status})
     else
        {:error, "Error: update_alert_status: invalid alert status type"}
     end
  end
  # confirmation_url_fun is a callback that gets passed a token and returns a url
  def deliver_user_alert_reply_instructions(%User{} = user, alert, build_url_func) do
    # {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
    # IO.puts("CREATING TOKEN")
    # IO.inspect(encoded_token)
    # IO.inspect(user_token)
    case build_and_insert_email_token(user, alert) do
      {_tokenized_url, _token, encoded_token} ->
        IO.inspect("INSERTED TOKEN")

        case UserNotifier.deliver_custom_alert(
               user,
               alert,
               build_url_func.(alert, user, encoded_token)
             ) do
          {:ok, email} ->
            {:ok, email}

          {:error, error} ->
            # IO.inspect(error, label: "error")
            {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  def build_and_insert_email_token(%User{} = user, alert) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
    # IO.puts("CREATING TOKEN")
    # IO.inspect(encoded_token)
    # IO.inspect(user_token)
    case Repo.insert(user_token) do
      {:ok, token} ->
        # IO.inspect(token, label: "INSERTED TOKEN")
        {TurnStile.Utils.build_user_alert_url(alert, user, encoded_token), token, encoded_token}

      {:error, error} ->
        {:error, error}
    end
  end


  @doc """
  Confirms a employee by the given token.
  - takes a encoded token string and checks if hashed token in DB matches
  - If token matches user is marked as confirmed; token is deleted.
  - timeout is checked with query; not set on the token itself
  """
  def confirm_user_email_token(encoded_token, user_id, opts \\ []) do
    # check if user exists
    case UserToken.verify_email_token_exists_query(encoded_token, "confirm") do
      {:ok, query} ->
        case Repo.one(query) do
          %User{} = user ->
            IO.inspect(user, label: "user")

            if user.id != TurnStile.Utils.convert_to_int() do
              IO.puts("confirm_user_email_token: User param ID does not match token")
              {nil, :not_matched}
            else
              # IO.puts("confirm_user_email_token: User Found")
            # check if user is expired
            case UserToken.verify_email_token_valid_query(query, "confirm") do
              {:ok, query} ->
                case Repo.one(query) do
                  %User{} = user ->
                    {:ok, user}
                    # run multi based on flag
                    case Keyword.fetch(opts, :skip) do
                      {:ok, true} ->
                        # return user
                        user
                      _ ->
                        # run multi
                        with {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
                          {:ok, user}
                        end
                    end

                  nil ->
                    IO.puts("confirm_user_email_token:User Expired")
                    {nil, :expired}
                end


            end
          end
          nil ->
              IO.puts("confirm_user_email_token: No User found")
              {nil, :not_found}
        end

      :invalid_input_token ->
        :invalid_input_token
    end
  end


  # skip - don't run multi in testing
  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))

    |> Ecto.Multi.delete_all(
      :tokens,
      UserToken.user_and_contexts_query(user, ["confirm"])
    )
  end

  @doc """
  Generates a session token.
  """
  def build_and_insert_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    IO.inspect(token, label: "token")
    IO.inspect(user_token, label: "user_token")
    IO.inspect(Base.encode16(token), label: "encoded user_token")
    Repo.insert!(user_token)
    {token, user_token}
  end

  @spec get_user_by_session_token(any) :: any
  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end
end
