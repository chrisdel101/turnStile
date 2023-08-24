defmodule TurnStileWeb.UserLive.Index.IndexUtils do
  import Ecto.Changeset
  import Phoenix.LiveView


  alias TurnStile.Patients
  alias TurnStile.Patients.UserToken
  alias TurnStileWeb.EmployeeAuth
  @dialyzer {:no_match, save_user: 3}
  @user_search_fields [:email, :phone, :last_name, :health_card_num]

  def maybe_delete_key(socket, key) do
    if socket.assigns[key] != nil do
      %{
        socket
        | assigns: Map.delete(socket.assigns, key)
      }
    else
      socket
    end
  end

  # edit from show - main edit current function
  # called in upsert
  def save_user(socket, :edit, user_params) do
    case Patients.update_user(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket =
          socket
          |> put_flash(:error, "User not created")

        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  # back from :display - on :search when existing users found
  # called in upsert
  def save_user(socket, :insert, user_params) do
    # IO.inspect(socket.assigns, label: "save_user :insert")
    current_employee = socket.assigns[:current_employee]
    # user changeset is passed back from :display, should exist in assigns
    changeset1 = Map.get(socket.assigns, :changeset) || Patients.change_user(user_params)
    # construct user struct
    user_struct = apply_changes(changeset1)
    # IO.inspect(user_struct, label: "user_struct :insert")
    # build new changeset: this time with a unique constraint on health_card_num; form validation
    changeset2 = Patients.change_user(user_struct, %{})
    # IO.inspect(changeset2, label: "save_user :insert2")
    organization =
      TurnStile.Company.get_organization(current_employee.current_organization_login_id)

    case Patients.build_user_changeset_w_assocs(changeset2, current_employee, organization) do
      %Ecto.Changeset{} = user_changeset ->
        # IO.inspect(user_changeset, label: "save_user :insert3")
        # send msg data to parent & redirect
        case Patients.insert_user_changeset(user_changeset) do
          {:ok, _user} ->
            {:noreply,
             socket
             |> put_flash(:success, "User created successfully")
             |> push_redirect(to: socket.assigns.return_to)}

          # failures here are due to contraints
          {:error, %Ecto.Changeset{} = changeset} ->
            socket =
              socket
              |> put_flash(:error, "Unable to create this user. See error messages below.")

            {:noreply, assign(socket, :changeset, changeset)}
        end

      # error occured in  build_user_changeset_w_assocs
      _ ->
        socket =
          socket
          |> put_flash(:error, "User not created: An error occured during creation")

        {:noreply, socket}
    end
  end

  # add new user from index page
  # called in upsert
  def save_user(socket, :new, user_params) do
    current_employee = socket.assigns[:current_employee]

    # IO.inspect(current_employee, label: "user_params: save_user")

    # check employee has organization role
    case TurnStile.Staff.check_employee_matches_organization(current_employee) do
      {:error, error} ->
        IO.puts("ERROR: #{error}")
        {:error, error}

      {:ok, _} ->
        # IO.puts("Employee matches_organization")
        # check employee has permissions
        case EmployeeAuth.has_user_add_permissions?(socket, current_employee) do
          true ->
            # IO.puts("Employee has correct permissions")
            organization =
              TurnStile.Company.get_organization(current_employee.current_organization_login_id)

            changeset = Patients.create_user(user_params)

            case Patients.build_user_changeset_w_assocs(changeset, current_employee, organization) do
              %Ecto.Changeset{} = user_changeset ->
                # send msg data to parent & redirect
                if send_existing_users_update?(user_changeset, socket) do
                  {:noreply, socket}
                else
                  case Patients.insert_user_changeset(user_changeset) do
                    {:ok, _user} ->
                      {:noreply,
                       socket
                       |> put_flash(:success, "User created successfully")
                       |> push_redirect(to: socket.assigns.return_to)}

                    {:error, %Ecto.Changeset{} = changeset} ->
                      socket =
                        socket
                        |> put_flash(:error, "User not created")

                      {:noreply, assign(socket, :changeset, changeset)}
                  end
                end

              # build_user_changeset_w_assocs not a User
              _ ->
                socket =
                  socket
                  |> put_flash(:error, "User not created: An error occured during creation")

                {:noreply, socket}
            end

          # has_user_add_permissions not true
          false ->
            IO.puts("Employee does not have correct permissions")

            socket =
              socket
              |> put_flash(:error, "Insuffient employee permissions to perform user add")

            {:noreply, socket}
        end
    end
  end

  defp send_existing_users_update?(user_changeset, socket) do
    case handle_existing_users_send_data(user_changeset, socket) do
      {:ok} ->
        true

      _ ->
        false
    end
  end

  defp handle_existing_users_send_data(user_changeset, socket) do
    current_employee = socket.assigns[:current_employee]
    user_struct = apply_changes(user_changeset)

    {search_field_name, search_field_value, existing_users} =
      lookup_user_direct(
        user_struct,
        length(@user_search_fields) - 1,
        (current_employee && current_employee.current_organization_login_id) || 0
      )

    # IO.inspect(existing_users , label: "existing_users")
    if length(existing_users) > 0 do
      send(
        self(),
        {:users_found,
         %{
           existing_users_found: existing_users,
           user_changeset: user_changeset,
           redirect_to:
           TurnStileWeb.Router.Helpers.user_index_path(
               socket,
               :display_existing_users,
               current_employee.current_organization_login_id,
               current_employee.id,
               search_field_name: search_field_name,
               search_field_value: search_field_value
             )
         }}
      )

      {:ok}
    else
      nil
    end
  end

  @doc """
  handle_generate_verification_code
  - generates a 6 digit alphanumeric code to give to user
  - inserts into DB so user can be verified
  """
  def handle_generate_verification_code(socket) do
    current_employee = socket.assigns[:current_employee]
    # generate a code
    code = UserToken.generate_user_verification_code(3)
    #  hash and insert into DB
    case Patients.build_and_insert_user_verification_code_token(code, current_employee.organization_id) do
      {user_url, _token, encoded_token} ->
        IO.inspect(user_url)
        IO.inspect(encoded_token)
        # optional pass user url here, maybe generate QR codes
        {:ok,
         socket
         |> maybe_assign_code(%{"code" => code})}

      {:error, error} ->
        {:error, error}
    end
  end

  def lookup_user_direct(_user_struct, nil, _organization_id), do: {nil, nil, []}
  def lookup_user_direct(_user_struct, 0, _organization_id), do: {nil, nil, []}

  def lookup_user_direct(user_struct, list_index, organization_id) do
    # search_fields are keys on user struct
    search_field_name = Enum.at(@user_search_fields, list_index)
    # IO.inspect(list_index, label: "list_index")
    # IO.inspect(search_field, label: "search_field")
    cond do
      # check if user has the key
      Map.get(user_struct, search_field_name) ->
        users =
          handle_get_users_by_field(
            search_field_name,
            Map.get(user_struct, search_field_name),
            organization_id
          )

        # IO.inspect(users, label: "USERS")
        if users === [] do
          # call recursively
          lookup_user_direct(user_struct, list_index - 1, organization_id)
        else
          # TODO: send field found by to display
          IO.puts("User(s) exist. Found by #{search_field_name}")
          search_field_value = Map.get(user_struct, search_field_name)
          {search_field_name, search_field_value, users}
        end

      true ->
        {:error, "Invalid search_field_name"}
    end
  end

  defp handle_get_users_by_field(field, field_value, organization_id) do
    case Patients.get_users_by_field(field, field_value, organization_id) do
      [] = _users ->
        # IO.puts("empty")
        []

      users ->
        # users
        # IO.inspect(users)
        users
    end
  end


  def maybe_assign_code(socket, nil), do: socket

  def maybe_assign_code(socket, %{"code" => code}) do
    socket = assign(socket, :code, code)
    socket
  end

  def extract_message_popup_index(message) do
    if !is_nil(message) do
      # get key from message; is an int
      key_single_list = Map.keys(message)
      # saftey check to avoid error
      if length(key_single_list) === 1 do
        # returns key as int
        {:ok, key} = Enum.fetch(key_single_list, 0)
        key
      else
        IO.puts("Error: extract_message_popup_index - message is not a single key value pair")
        # TODO: think of better soluton
        9999
      end
    end
  end

  def extract_message_popup_user_params(nil), do: nil

  def extract_message_popup_user_params(message) do
    # get values side of map - is a list
    values = Map.values(message)
    # make sure list is 1 item
    if length(values) === 1 do
      # extact single item from list
      {:ok, value} = Enum.fetch(values, 0)
      # confirm single item is a map
      if is_map(value) do
        value
      else
        IO.puts(
          "Error: extract_message_popup_user_params - message is not a single key value pair"
        )

        "User Name Not Found"
      end
    else
      IO.puts("Error: extract_message_popup_user_params - message is not a single key value pair")
      nil
    end
  end
end
