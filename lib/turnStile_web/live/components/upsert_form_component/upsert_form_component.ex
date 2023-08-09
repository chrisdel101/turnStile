defmodule TurnStileWeb.UserLive.UpsertFormComponent do
  # handles the logic for the modals
  use TurnStileWeb, :live_component
  import Ecto.Changeset
  alias TurnStileWeb.EmployeeAuth
  alias TurnStile.Patients
  alias TurnStile.Patients.User

  @user_search_fields [:email, :phone, :last_name, :health_card_num]

  @impl true
  # empty user struct getting passed as props; see index apply_action(:new)
  # - search insert passes user struct
  # - dispay insert passes a user changeset
  def update(%{user: user, action: action, user_changeset: user_changeset} = props, socket) do
    # IO.inspect(props, label: "props")
    # IO.inspect(action)
    user =
      case user do
        # :insert: from search: it's a formed user then fill in the form
        %User{} ->
          user
        # :new: if user is empty map it's a blank user form
        %{} ->
          %User{}
        # if form is opened out of sequence, stop error by setting user to
        nil ->
          %User{}
      end
      # IO.inspect(action)
      # build default user changeset
    changeset = if !is_nil(user_changeset), do: user_changeset, else: Patients.change_user(user)
    # IO.inspect(changeset, label: "changeset upsert")

    {:ok,
     socket
     |> assign(props)
     # assign user struct so 'validate' works
     |> assign(:user, apply_changes(changeset))
     |> assign(:live_action, action)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    # IO.inspect(socket.assigns.user, label: "user_params")
    changeset =
      socket.assigns.user
      |> Patients.change_user(user_params)
      |> Map.put(:action, :validate)

    # IO.inspect(changeset, label: "VALIDATE")
    {:noreply, assign(socket, :changeset, changeset)}
  end

  # only fires on change- handles changing the form based on radio button selection
  def handle_event("radio_click", %{"user" => %{"alert_format_set" => alert_format}}, socket) do
    # IO.inspect(socket.assigns.changeset, label: "radio_click")
    # IO.inspect(alert_format, label: "radio_click")

    # # check for changes when radio click
    if alert_format && Map.has_key?(socket.assigns.changeset, :data) do
      # check which type of alert to change
      cond do
        # radio - flip to email form
        alert_format === AlertFormatTypesMap.get_alert("EMAIL") ->
          # sets up changeset for template use
          changeset =
            Ecto.Changeset.change(socket.assigns.changeset, alert_format_set: alert_format)

          # IO.inspect(changeset, label: "changeset radio email")

          {:noreply, assign(socket, :changeset, changeset)}

        # end
        alert_format === AlertFormatTypesMap.get_alert("SMS") ->
          changeset =
            Ecto.Changeset.change(socket.assigns.changeset, alert_format_set: alert_format)

          # IO.inspect(changeset, label: "changeset radio SMS")

          {:noreply, assign(socket, :changeset, changeset)}

        true ->
          IO.puts("upsert handle_event: NO keys")
          {:noreply, socket}
      end
    end
  end

  def handle_event("save", %{"user" => _user_params}, socket) do
      handle_send_data(socket)
      {:noreply, socket}
  end

  # handle save for new and edit
  def handle_event("save", %{"user" => user_params}, socket) do
    current_employee = socket.assigns[:current_employee]
    # IO.inspect(socket.assigns, label: "action")
    # no submit if validation errors
    if !socket.assigns.changeset.valid? do
      handle_event("validate", %{"user" => user_params}, socket)
    else
      case socket.assigns.action do
        action when action in [:edit] ->
          if EmployeeAuth.has_user_edit_permissions?(socket, current_employee) do
            save_user(socket, socket.assigns.action, user_params)
          else
            socket =
              socket
              |> put_flash(:error, "Insuffient permissions to perform user edit")
              |> push_redirect(to: socket.assigns.return_to)

            {:noreply, socket}
          end

        :new ->
          if EmployeeAuth.has_user_add_permissions?(socket, current_employee) do
            save_user(socket, socket.assigns.action, user_params)
          else
            socket =
              socket
              |> put_flash(:error, "Insuffient permissions to perform user add")
              |> push_redirect(to: socket.assigns.return_to)

            {:noreply, socket}
          end

        _ ->
          {:noreply, socket}
      end
    end
  end

  # edit from show - main edit current function
  defp save_user(socket, :edit, user_params) do
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
  # add new user from index page
  # defp save_user(socket, :new, user_params) do
  #   IO.puts("FIRED")
  #   # current_employee = socket.assigns[:current_employee]
  #   # socket = assign(socket, existing_users: [1,2,3])
  #   # send self(), {:dislay, users: [1,2,3]}
  #   # {:noreply, socket}
  #   send self(), {:updated_card, card: "CARD123"}
  defp save_user(socket, :new, user_params) do
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
                # handle_send_data(socket)
                # IO.inspect(user_changeset, label: "user_changeset")
                # check if user already exists
                {search_field_name, search_field_value, existing_users} = lookup_user_direct(
                  %User{} = apply_changes(user_changeset),
                  length(@user_search_fields) -1
                )
                # if is user exists redirect to search list
                # IO.inspect(existing_users, label: "existing_users")
                if length(existing_users) > 0 do
                  send(self(),
                  {:users_found,
                  %{existing_users_found: existing_users,
                   user_changeset: user_changeset,
                   redirect_to: Routes.user_index_path(socket, :display, current_employee.current_organization_login_id, current_employee.id, search_field_name: search_field_name, search_field_value: search_field_value) }})
                  {:noreply, socket}
                    else
                  case Patients.insert_user_changeset(user_changeset) do
                    {:ok, _user} ->
                      {:noreply,
                       socket
                       |> put_flash(:info, "User created successfully")
                       |> push_redirect(to: socket.assigns.return_to)}

                    {:error, %Ecto.Changeset{} = changeset} ->
                      socket =
                        socket
                        |> put_flash(:error, "User not created")

                      {:noreply, assign(socket, :changeset, changeset)}
                  end
                end

              _ ->
                socket =
                  socket
                  |> put_flash(:error, "User not created: An error occured during creation")

                {:noreply, socket}
            end

          false ->
            IO.puts("Employee does not have correct permissions")

            socket =
              socket
              |> put_flash(:error, "Insuffient employee permissions to perform user add")

            {:noreply, socket}
        end
    end
  end

  @doc """
  Lookup user by field
  - search users by fields; does direct queries only; is not a search, only queries by exact match ILIKE
  ; returns list of users or []
  - loop from end of list user_search_fields checking each; if none, call func with next
  - if index is 0 end loop
  """
  def lookup_user_direct(_user_struct, nil), do: {nil, nil, []}
  def lookup_user_direct(_user_struct, 0), do: {nil, nil, []}
  def lookup_user_direct(user_struct, list_index) do
    search_field_name = Enum.at(@user_search_fields, list_index)
    # IO.inspect(list_index, label: "list_index")
    # IO.inspect(search_field, label: "search_field")
    cond do
      Map.get(user_struct, search_field_name) ->
        users = handle_get_users_by_field(search_field_name, Map.get(user_struct, search_field_name))
        # IO.inspect(users, label: "USERS")
        if users === [] do
          # call recursively
          lookup_user_direct(user_struct, list_index - 1)
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

  defp handle_get_users_by_field(field, field_value) do
    case Patients.get_users_by_field(field, field_value) do
      [] = _users ->
        # IO.puts("empty")
        []
      users ->
        # users
        # IO.inspect(users)
        users
    end
  end

  defp handle_send_data(socket) do
    current_employee = socket.assigns[:current_employee]
    user_struct = TurnStile.Patients.get_user(1)
    user_changeset = Patients.change_user(user_struct)
    {search_field_name, search_field_value, existing_users} = lookup_user_direct(
      user_struct,
      length(@user_search_fields) -1
    )
    if length(existing_users) > 0 do
      # Phoenix.PubSub.broadcast(TurnStile.PubSub, PubSubTopicsMap.get_topic("EXISTING_USERS"), %{
      #   "existing_users" => existing_users,
      #   "user_changeset" => user_changeset
      # })
      # socket
      # |> assign(:existing_users, existing_users)
      # |> assign(:user_changeset, existing_users)
      # {:noreply,
      # socket
      # |> push_patch(to: Routes.user_index_path(socket, :display, current_employee.current_organization_login_id, current_employee.id, search_field_name: search_field_name, search_field_value: search_field_value))}
    send(self(),
    {:users_found,
    %{existing_users_found: existing_users,
      user_changeset: user_changeset,
      redirect_to: Routes.user_index_path(socket, :display, current_employee.current_organization_login_id, current_employee.id, search_field_name: search_field_name, search_field_value: search_field_value) }})
    end
  end
  defp is_user_active?(user) do
    user.active
  end

  defp maybe_store_return_to(socket) do

  end
end
