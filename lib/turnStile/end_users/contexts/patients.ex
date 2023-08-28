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

  @now NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  @dialyzer {:no_match, confirm_user_session_token: 2}
  @dialyzer {:no_match, get_user_by_session_token: 1}



  @doc """
  user_organization_base_query
  - return all users with the matching organization_id
  - should be base query for all other user queries
  """
  def user_organization_base_query(organization_id) do
    from User, where: [organization_id: ^organization_id]
  end
 @doc """
  list_users
  - query for all users within an organization
  - use base query that keeps within the organization
 """
  def list_users(organization_id) do
    if !is_nil(organization_id) do
      q =
        from user in user_organization_base_query(organization_id),
          join: organization in assoc(user, :organization),
          preload: [:employee, :organization],
          order_by: [desc: user.inserted_at]
      Repo.all(q)
    end
  end
  @doc """
  list_active_users_query
  - query for all active users within an organization
  - use base query that keeps within the organization
  """
  def list_active_users_query(organization_id) do
    if !is_nil(organization_id) do
      from user in user_organization_base_query(organization_id),
      join: organization in assoc(user, :organization),
      where: user.is_active? == true
    end
  end

  # use active query and refine it little
  def list_active_users(organization_id) do
    q =
      from(u in list_active_users_query(organization_id),
        preload: [:employee, :organization],
        order_by: [desc: u.inserted_at]
      )

    Repo.all(q)
  end
  @doc """
  filter_active_users_x_mins_past_last_update
  """
  # - use active query to get deactivated w/in a time period - less/eq to x mins ago
  # -  handles listing users based on normal operations: keeps deactivated users in the list for info purposes
  def filter_active_users_x_mins_past_last_update(organization_id, duration_in_mins) do
    q =
      from(u in list_active_users_query(organization_id),
        # interval = current time - updated_at
        # time_ago > or < interval
        # ago: Subtracts the given interval from the current time in UTC.
        # - > < are reversed with ago
        # > means further back than x time ago (before)
        # < means before x time ago (after)
        or_where: u.is_active? == false and u.updated_at > ago(^duration_in_mins, "minute"),
        preload: [:employee, :organization],
        order_by: [desc: u.id]
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
  @doc """
  get_users_by_field
  - check if a user has a key value pair
  - two versions: one for string and one for integer
  - make sure to limit users to w.in organization
  """
  # handle when value is a string
  def get_users_by_field(field, value, organization_id) when is_binary(value) do
    if is_nil(organization_id) do
      raise RuntimeError, "Error: get_users_by_field: organization_id cannot be nil"
    else
      if is_atom(field) do
        q =
          from user in user_organization_base_query(organization_id),
            join: organization in assoc(user, :organization),
            where: ilike(field(user, ^field), ^String.downcase(value)),
            preload: [:employee, :organization]
          Repo.all(q)
      else
        IO.puts("get_users_by_field: field must be an atom")
      end
    end
  end
  # handle when value is an integer
  def get_users_by_field(field, value, organization_id) when is_integer(value) do
    if is_nil(organization_id) do
      raise RuntimeError, "Error: get_users_by_field: organization_id cannot be nil"
    else
      if is_atom(field) do
        q =
          from user in user_organization_base_query(organization_id),
            join: organization in assoc(user, :organization),
            where: field(user, ^field) == ^value,
            preload: [:employee, :organization]
        Repo.all(q)
      else
        IO.puts("get_users_by_field: field must be an atom")
      end
    end
  end
  @doc """
  get_all_users_by_phone
  - look up ALL user by phone number - regardless of organization
  - comes from twilio so we do not know the org yet
  # - there could be multiple users w. the same phone so returns a list
  # TODO - make more robust search
  # -needs to check if input number matches also for 1, and +1
  # - need to check if t  here is match of input w/ a 1 or +1
  """
  def get_all_users_by_phone(phone) do
    if !is_nil(phone) do
      # remove leading 1 and +; ignore otherwise
      phone = String.trim(TurnStile.Utils.remove_first_string_char(phone, "+"))
      phone = String.trim(TurnStile.Utils.remove_first_string_char(phone, "1"))
      # IO.inspect("phone: " <> phone)
      q =
        from(u in User,
          where: u.phone == ^phone,
          order_by: [desc: u.inserted_at],
          preload: [:employee, :organization]
        )

      Repo.all(q)
    end
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
  search_users_by_last_and_first_name
  - runs through 3 queries to find a user; starts simple and progresses to use levenstein
  - set last name levenstein 1 to allow one typo in name
  - set firt name levenstein 2 to allow 2 typo in name: let first name be flexible
  - first name is optional
  """
  def search_users_by_last_and_first_name(last_name, first_name,organization_id, levenstein_val_last_name_query \\ 1, levenstein_val_first_name_query \\ 2) do
      # query for both names first before more indepth indepedent searhes
      case check_both_name_direct = search_last_name_and_first_name_direct(first_name, last_name, organization_id) do
        users when not is_nil(check_both_name_direct) and length(check_both_name_direct) > 0 ->
          users
      _  ->
        case check_both_names_ilike = search_last_name_and_first_name_ilike(last_name, first_name, organization_id) do
          users when not is_nil(check_both_names_ilike) and length(check_both_names_ilike) > 0 ->
          users
        _ ->
          # IO.inspect(last_name, label: 'last_name')
          # run direct search with just last name
          first_search_result = Repo.all(search_last_name_direct_query(last_name, organization_id))
          # IO.inspect("first_search_resul1t: #{inspect(first_search_result)}")
          if !is_nil(first_search_result) && length(first_search_result) > 0 do
            # IO.inspect("first_search_result1: #{inspect(first_search_result)}")
            # if multiple with last name, narrow down last name search by first name
            if length(first_search_result) > 1 && !is_nil(first_name) do
              IO.inspect("first_search_result refine: #{inspect(first_search_result)}")
              refine_query_by_appending_first_name(
                search_last_name_direct_query(last_name, organization_id),
                first_name,
                levenstein_val_first_name_query
              )
            else
              IO.inspect("first_search_result success: #{inspect(first_search_result)}")
              # if single last name return it
              first_search_result
            end
          else
            # run search with LIKE parameter
            second_search_result = Repo.all(search_last_name_ilike_query(last_name, organization_id))

            if !is_nil(second_search_result) && length(second_search_result) > 0 do
              IO.inspect("second_search_result: #{inspect(second_search_result)}")
              # if multiple with last name, narrow down last name search by first name
              if length(second_search_result) > 1 && !is_nil(first_name) do
                refine_query_by_appending_first_name(
                  search_last_name_ilike_query(last_name, organization_id),
                  first_name,
                  levenstein_val_first_name_query
                )
              else
                # return single result
                second_search_result
              end
            else
              # run seach with levenstein
              users = Repo.all(search_user_last_name_levenstein_query(last_name, organization_id, levenstein_val_last_name_query))
              # narrow down last name search by first name
               IO.inspect("third search result: #{inspect(users)}")
              if length(users) > 1 && !is_nil(first_name) do
                refine_query_by_appending_first_name(
                  search_user_last_name_levenstein_query(last_name, organization_id, levenstein_val_last_name_query),
                  first_name,
                  levenstein_val_first_name_query
                )
              else
                users
              end
            end
          end

        end
      end

  end
  # if search by last name fails run this on single input
  def search_users_by_first_name(first_name, organization_id) do
    # run direct search
    first_search_result = Repo.all(search_first_name_direct_query(first_name, organization_id))
    # if no results run next query
    if length(first_search_result) === 0 do
      second_search_result = Repo.all(search_first_name_ilike_query(first_name, organization_id))
          # if no results run next query
      if length(second_search_result) === 0 do
        # run seach with levenstein
        Repo.all(search_first_name_levenshtein_query(first_name, organization_id))
      else
        second_search_result
      end
    else
      first_search_result
    end
  end

  @doc """
  refine_query_by_appending_first_name
  - runs through 3 queries to find a user; starts simple and progresses to use levenstein
  - set levenstein 1 to allow one typo in name
  """
  def refine_query_by_appending_first_name(last_name_query, first_name, levenstein_level \\ 1) do
    # run direct search
    first_search_result = Repo.all(append_first_name_direct_query(last_name_query, first_name))
    # IO.inspect(first_search_result, label: "FIRST NAME: first_search_result")
    if !is_nil(first_search_result) && length(first_search_result) > 0 do
      first_search_result
    else
      # run search with LIKE parameter
      second_search_result = Repo.all(append_first_name_like_query(last_name_query, first_name))
      # IO.inspect(second_search_result, label: "FIRSTNAME: second_search_result")
      if !is_nil(second_search_result) && length(second_search_result) > 0 do
        second_search_result
      else
        # run seach with levenstein
        # IO.inspect(append_first_name_levenshtein_query(last_name_query, first_name, levenstein_level), label: "ZZZZZ")

          Repo.all(
            append_first_name_levenshtein_query(last_name_query, first_name, levenstein_level)
          )
      end
    end
  end
  def search_last_name_and_first_name_ilike(first_name, last_name, organization_id) do
     if !is_nil(first_name) && !is_nil(last_name) do
      q = (from user in user_organization_base_query(organization_id),
        join: organization in assoc(user, :organization),
        where: ilike(user.last_name, ^"%#{last_name}%") and ilike(user.first_name, ^"%#{first_name}%"),
        select: user
      )
      Repo.all(q)
    end
  end
  def search_last_name_and_first_name_direct(first_name, last_name, organization_id) do
    if !is_nil(first_name) && !is_nil(last_name) do
      q = from user in user_organization_base_query(organization_id),
        join: organization in assoc(user, :organization),
        where: user.last_name == ^last_name and user.first_name == ^first_name,
        select: user
      Repo.all(q)
    end
  end

  def search_last_name_direct_query(last_name, organization_id) do
    from(user in user_organization_base_query(organization_id),
      join: organization in assoc(user, :organization),
      where: user.last_name == ^last_name,
      select: user
    )
  end

  def search_last_name_ilike_query(last_name, organization_id) do
    from(user in user_organization_base_query(organization_id),
      join: organization in assoc(user, :organization),
      where: ilike(user.last_name, ^"%#{last_name}%"),
      select: user
    )
  end

  def search_user_last_name_levenstein_query(last_name, organization_id, levenstein_level) do
    from(user in user_organization_base_query(organization_id),
      join: organization in assoc(user, :organization),
      where: fragment("levenshtein(LOWER(last_name), ?) <= ?", ^last_name, ^levenstein_level),
      select: user
    )
  end

  # is passed formed query for last name
  def append_first_name_direct_query(last_name_query, first_name) do
    from(u in last_name_query,
      where: u.first_name == ^first_name
    )
  end

  # is passed formed query for last name
  def append_first_name_like_query(last_name_query, first_name) do
    from(u in last_name_query,
      where: like(u.first_name, ^"%#{first_name}%")
    )
  end

  # is passed formed query for last name
  def append_first_name_levenshtein_query(last_name_query, first_name, levenstein_level) do
    from(u in last_name_query,
      where:
        fragment("levenshtein(LOWER(first_name), LOWER(?)) <= ?", ^first_name, ^levenstein_level)
    )
  end
  def search_first_name_direct_query(first_name, organization_id) do
    from(user in user_organization_base_query(organization_id),
      join: organization in assoc(user, :organization),
      where: fragment("lower(?) = lower(?)", user.first_name, ^first_name),
      select: user
    )
  end

  def search_first_name_ilike_query(first_name, organization_id) do
    from(user in user_organization_base_query(organization_id),
      join: organization in assoc(user, :organization),
      where: ilike(user.first_name, ^"%#{first_name}%"),
      select: user
    )
  end
  def search_first_name_levenshtein_query(first_name, organization_id, levenstein_level \\ 1) do
    from(user in user_organization_base_query(organization_id),
      join: organization in assoc(user, :organization),
      where:
        fragment("levenshtein(LOWER(first_name), LOWER(?)) <= ?", ^first_name, ^levenstein_level),
      select: user
    )
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
    |> User.create_changeset(attrs)
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
          # IO.inspect(user_struct, label: "organization struct123")
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
        # IO.inspect(user_struct, label: "organization struct123")
        {:ok, user_struct}
    end
  end

  def build_user_changeset_w_assocs(user_changeset, employee_struct, org_struct) do
    updated_user_e_changeset =
      Ecto.Changeset.put_assoc(user_changeset, :employee, employee_struct)

    Ecto.Changeset.put_assoc(updated_user_e_changeset, :organization, org_struct)
  end

  def insert_user_struct(user) do
    # convert val to int
    user = Map.put(user, :health_card_num, TurnStile.Utils.convert_to_int(user.health_card_num))

    case Repo.insert(maybe_set_is_activated(user)) do
      {:ok, user} ->
        {:ok,
         user
         |> Repo.preload([:employee, :organization])}

      {:error, error} ->
        {:error, error}
    end
  end

  def insert_user_changeset(user_changeset) do
  # when health card num, is a string
  user =
    # make sure it exists as a change
    case Ecto.Changeset.get_change(user_changeset, :health_card_num) do
      val when is_binary(val) ->
        IO.inspect(val, label: "val")
        Ecto.Changeset.put_change(
        user_changeset,
        :health_card_num,
        TurnStile.Utils.convert_to_int(user_changeset.changes.health_card_num)
      )
      _ ->
        user_changeset
      end

    case Repo.insert(maybe_set_is_activated(user)) do
      {:ok, user} ->
        {:ok,
         user
         |> Repo.preload([:employee, :organization])}

      {:error, error} ->
        {:error, error}

    end
  end
  # takes changeset
  defp maybe_set_is_activated(%Ecto.Changeset{} = user) do
    if Ecto.Changeset.get_field(user, :is_active?) do
      user
    |> Ecto.Changeset.put_change(:activated_at, @now)
    else
      user
    end
  end
    # takes struct
  defp maybe_set_is_activated(%User{} = user) do
    if user.is_active? do
      user
      |> Map.put(:activated_at, @now)
    else
      user
    end
  end

  def check_user_assoc_in_organization(user_struct, organization_id) do
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
    changeset =
      user
      |> User.update_changeset(attrs)
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
  # Admin mgmt only; delete priveleges required
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  # sets user to inactive; keeps on file
  def deactivate_user(%User{} = user) do
    IO.inspect(user, label: "user")
    # new_user = change_user(user, %{is_active?: false})
    {:ok, new_user} = update_user(user, %{is_active?: false, deactivated_at: @now})
    IO.inspect(new_user, label: "new_user")
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.update_changeset(user, attrs)
  end

  #  NO preloading - may cause error later
  def update_alert_status(user, new_alert_status) do
    # IO.inspect(user)
    # IO.inspect(new_alert_status)
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

  @doc """
  deliver_user_email_alert_reply_instructions
  - handles the
  """
  # confirmation_url_fun is a callback that gets passed a token and returns a url (i.e &TurnStile.Utils.build_user_alert_url(&1, &2)))
  def deliver_user_email_alert_reply_instructions(%User{} = user, alert, build_url_func) do
    # {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
    # IO.puts("CREATING TOKEN")
    # IO.inspect(encoded_token)
    # IO.inspect(user_token)
    case build_and_insert_email_token(user) do
      {tokenized_url, _token, encoded_token} ->
        IO.inspect(tokenized_url, label: "build_and_insert_email_token URL")

        cond do
          alert.alert_category === AlertCategoryTypesMap.get_alert("INITIAL") ->
            case UserNotifier.deliver_initial_alert(
                   user,
                   alert,
                   build_url_func.(user, encoded_token)
                 ) do
              {:ok, email} ->
                {:ok, email}

              {:error, error} ->
                # IO.inspect(error, label: "error")
                {:error, error}
            end

          alert.alert_category === AlertCategoryTypesMap.get_alert("CUSTOM") ->
            case UserNotifier.deliver_custom_alert(
                   user,
                   alert,
                   build_url_func.(user, encoded_token)
                 ) do
              {:ok, email} ->
                {:ok, email}

              {:error, error} ->
                # IO.inspect(error, label: "error")
                {:error, error}
            end

          true ->
            {:error,
             "Error: deliver_user_email_alert_reply_instructions: invalid alert category type. Only INITIAL and CUSTOM are valid."}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  confirm_user_session_token
  Confirms a employee by the given token.
  - takes bytes token; matches w hash in DB
  - If expired, returns {:expired, user1}
  - If not matched, returns  {nil, :not_found}
  returns [{:ok, user2}, {:expired, user1}, {nil, :not_found}, invalid_input_token]
  - expiry is checked with query; not set on the token itself
  """
  def confirm_user_session_token(token, _opts \\ []) do
    # check if user exists
    # token = Base.encode64(token)
    case UserToken.verify_session_token_exists_query(token) do
      {:ok, query} ->
        # IO.inspect(query, label: "query")
        case Repo.one(query) do
          %User{} = user1 ->
            # IO.inspect(user, label: "user EXISTS confirm_user_session_token
            #   ")
            # check if user is expired
            case UserToken.verify_session_token_valid_query(query) do
              {:ok, query} ->
                case Repo.one(query) do
                  %User{} = user2 ->
                    # IO.inspect(user, label: "user VALID confirm_user_session_token
                    # ")
                    {:ok, user2}

                  nil ->
                    # IO.puts("confirm_user_session_token: User Found but Expired")
                    {:expired, user1}
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

  # - checks for user token existence but ignores expiration
  def confirm_user_session_token_exists(token, _opts \\ []) do
    # check if user exists
    # token = Base.encode64(token)
    case UserToken.verify_session_token_exists_query(token) do
      {:ok, query} ->
        Repo.one(query) |> Repo.preload([:employee, :organization])
    end
  end

  def confirm_user_email_token(encoded_token, _opts \\ []) do
    # check if user exists
    case UserToken.verify_email_token_exists_query(encoded_token, "confirm") do
      {:ok, query} ->
        case Repo.one(query) do
          %User{} = _user ->
            # IO.puts("confirm_user_email_token: User Found")
            # if token is not found here, it is expired
            case UserToken.verify_email_token_valid_query(query, "confirm") do
              {:ok, query} ->
                case Repo.one(query) do
                  %User{} = user ->
                    {:ok, user}
                      {:ok, user}
                    nil ->
                      IO.puts("confirm_user_email_token: User Expired")
                      {nil, :expired}
                    {:error, error} ->
                      {:error, error}
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
  @doc """
  confirm_user_verification_token
  - First: takes encoded token and checks DB for match
  - Second: checks for non-expired token
  """
  def confirm_user_verification_token(encoded_token, _opts \\ []) do
    # IO.inspect(encoded_token, label: 'encoded_token')
    # check if user exists query
    case UserToken.verify_verification_token_exists_query(encoded_token, "verification") do
      {:ok, query} ->
        # IO.inspect(Repo.one(query), label: "HERE")
        # check if token exist
        case Repo.one(query) do
          nil ->
            IO.puts("confirm_user_verification_token: No token found")
            {nil, :not_found}
            # means token does exist
          %UserToken{} = user_token ->
            # IO.inspect(user_token.token, label: "confirm_user_verification_token token")
            with {:ok, %Ecto.Query{} = query2} <- UserToken.verify_verification_token_valid_query(query, "verification") do
                # so token does not expired
                case Repo.one(query2) do
                  %UserToken{} = user_token2 ->
                    {:ok, user_token2}
                  nil ->
                    IO.puts("confirm_user_verification_token: token expired")
                    {:expired, user_token}
                end
            end
        end

      :invalid_input_token ->
        :invalid_input_token
    end
  end

  # skip - don't run multi in testing
  def confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(
      :tokens,
      UserToken.user_and_contexts_query(user, ["confirm"])
    )
  end

  @doc """
  Generates a verification code token. used for user to register themsevlves when give a verification code
  """
  def build_and_insert_user_verification_code_token(user_verification_token, organization_id) do
    {encoded_token, user_token} = UserToken.build_verification_code_token(user_verification_token, organization_id)
    # IO.inspect(encoded_token, label: "encoded user_token")
    case Repo.insert(user_token) do
      {:ok, token} ->
        {
          TurnStile.Utils.build_user_registration_url(encoded_token, organization_id),
          token, encoded_token
        }

      {:error, error} ->
        {:error, error}
    end
  end
  @doc """
  Generates a session token.
  """
  def build_and_insert_user_session_token(user) do
    {_token, user_token} = UserToken.build_session_token(user)
    # IO.inspect(Base.encode16(token), label: "encoded user_token")
    if !is_token_user_id_nil?(user_token) do
      case Repo.insert(user_token) do
        {:ok, token} ->
          {token.token, token}

        {:error, error} ->
          {:error, error}
      end
    else
      {:error, "Error: build_and_insert_user_session_token: null value in column 'user_id' violates not-null constraint"}
    end
  end

  @doc """
  build_and_insert_email_token
  - takes user and alert and builds token to handle email alert URL
  - inserts token into DB
  - returns tokenized url, token, and encoded token; usable in iex w tokenized_url
  """
  def build_and_insert_email_token(%User{} = user) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")

    # IO.puts("CREATING TOKEN")
    # IO.inspect(encoded_token)
    # IO.inspect(user_token)
    if !is_token_user_id_nil?(user_token) do
      case Repo.insert(user_token) do
        {:ok, token} ->
          # IO.inspect(token, label: "INSERTED TOKEN")
          {TurnStile.Utils.build_user_alert_url(user, encoded_token), token, encoded_token}

        {:error, error} ->
          {:error, error}
      end
    else
      {:error, "Error: build_and_insert_email_token: null value in column 'user_id' violates not-null constraint"}
    end
  end

  @doc """
  Gets the user with the given signed token.
  - essentially just calls confirm_user_session_token and returns user or nil; handles confirm_user_session_token return values
  """
  def get_user_by_session_token(token) do
    # IO.puts("get_user_by_session_token fired")
    case confirm_user_session_token(token) do
      {:ok, user} ->
        user

      {:expired, %User{} = _user} ->
        nil

      {nil, :not_found} ->
        nil

      :invalid_input_token ->
        IO.puts("Error: get_user_by_session_token: invalid input token")
        nil
    end

    # {:ok, query} = UserToken.verify_session_token_exists_query(token)
  end

  @doc """
  delete_email_token
  Deletes the passed in token; when expired token is accessed it is deleted
  """
  def delete_email_token(token) do
    Repo.delete(token)
  end
  @doc """
  delete_verification_token
  Deletes the passed in token; same as above diff naming
  """
  def delete_verification_token(token) do
    Repo.delete(token)
  end

  def delete_expired_verification_tokens do
    {:ok, query} = UserToken.list_all_expired_verification_tokens_query
    Repo.delete_all(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  def reset_user_alert_status(user) do
    update_user(user, %{user_alert_status: "unalerted"})
  end

  defp is_token_user_id_nil?(token) do
    is_nil(Map.get(token, :user_id))
  end
end
