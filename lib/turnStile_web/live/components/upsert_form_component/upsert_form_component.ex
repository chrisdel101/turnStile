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

  def update(%{user: user, action: action} = assigns, socket) do
    # IO.inspect(user, label: "user")
    # IO.inspect(action)
    user =
      case user do
        # :insert: it's a formed user then fill in the form
        %User{} = user ->
          user

        # :new: if user is empty map it's a blank user form
        %{} = user ->
          %User{}
      end
      # IO.inspect(user, label: "user")
      # IO.inspect(action)
    # build default user changeset
    changeset = Patients.change_user(user)

    {:ok,
     socket
     |> assign(assigns)
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
                IO.inspect(user_changeset, label: "user_changeset")
                # check if user already exists
                existing_users = lookup_user(
                  %User{} = apply_changes(user_changeset),
                  length(@user_search_fields) -1
                )
                # if is user exists redirect to search list
                # IO.inspect(existing_users, label: "existing_users")
                if length(existing_users) > 0 do
                  # assign users to socket
                  socket =
                    socket
                  |> assign(:users, existing_users)
                  # display users list
                  {:noreply, push_patch(socket, to: Routes.user_index_path(socket, :display, current_employee.current_organization_login_id, current_employee.id))}
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
  - search users by fields; does direct queries only, nothing extra
  ; returns list of users or []
  - loop from end of list user_search_fields checking each; if none, call func with next
  - if index is 0 end loop
  """
  def lookup_user(user_struct, nil), do: []
  def lookup_user(user_struct, 0), do: []
  def lookup_user(user_struct, list_index) do
    search_field = Enum.at(@user_search_fields, list_index)
    # IO.inspect(list_index, label: "list_index")
    # IO.inspect(search_field, label: "search_field")
    cond do
      Map.get(user_struct, search_field) ->
        users = handle_get_users_by_field(search_field, Map.get(user_struct, search_field))
        # IO.inspect(users, label: "USERS")
        if users === [] do
          # call recursively
          lookup_user(user_struct, list_index - 1)
        else
          # TODO: send field found by to display
          IO.puts("User(s) exist. Found by #{search_field}")
          users
        end

      true ->
        {:error, "Invalid search_field"}
    end
  end

  defp handle_get_users_by_field(field, field_value) do
    case Patients.get_users_by_field(field, field_value) do
      [] = users ->
        # IO.puts("empty")
        []
      users ->
        # users
        # IO.inspect(users)
        users
    end
  end

  defp is_user_active?(user) do
    user.active
  end
end
