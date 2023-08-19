defmodule TurnStileWeb.UserLive.UpsertFormComponent do
  # handles the logic for the modals
  use TurnStileWeb, :live_component
  import Ecto.Changeset
  alias TurnStileWeb.EmployeeAuth
  alias TurnStile.Patients
  alias TurnStile.Patients.User
  @dialyzer {:no_match, save_user: 3}

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
        # :insert: from search: it's a formed user struct then fill in the form
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

    disable_input = if action && action === :select, do: true, else: false

    disabled_hover_info =
      if disable_input === true, do: "Form is readonly. To edit, go back.", else: nil

    {:ok,
     socket
     |> assign(props)
     #  disable form on :select - make readonly
     |> assign(:disable_input, disable_input)
     #  add 'title' attr for user info purposes
     |> assign(:disabled_hover_info, disabled_hover_info)
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
    # IO.inspect(user_params, label: "user_params")
    IO.inspect(socket.assigns.action, label: "handle_event upsert: action")
    if !socket.assigns.changeset.valid? do
      # no submit if validation errors
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

        # creating new employee
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

        # returning to form with changeset; on existing users reject
        :insert ->
          # IO.inspect(socket.assigns.action, label: "AAAAAA")
          if EmployeeAuth.has_user_add_permissions?(socket, current_employee) do
            save_user(socket, socket.assigns.action, user_params)
          else
            socket =
              socket
              |> put_flash(:error, "Insuffient permissions to perform user add")
              |> push_redirect(to: socket.assigns.return_to)

            {:noreply, socket}
          end

        :select ->
          # IO.inspect(socket.assigns.action, label: "AAAAAA")
          if EmployeeAuth.has_user_add_permissions?(socket, current_employee) do
            activate_user(socket, socket.assigns.action, user_params)
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

  # back from :display - on :new when existing users found
  defp activate_user(socket, action, _user_params) when action in [:select, :insert] do
    # should have access to use passed from display
    user = socket.assigns[:user]
    # check if user is already active
    if user && user.is_active? do
      socket =
        socket
        |> put_flash(
          :warning,
          "This user is aleady active and should be in the main list. Look through your list of users again."
        )

      {:noreply, socket}
    else
      with user_changeset <- Patients.change_user(user, %{is_active?: true}),
          # if changes are valid
          true <- Ecto.Changeset.get_change(user_changeset, :is_active?) do

            case TurnStile.Repo.update(user_changeset) do
              {:ok, user} ->
                IO.inspect(user, label: "activate_user :update user")
                # send update to :index - refresh the list
                send(self(), :update)
                # TODO: redirect to index
                socket =
                  socket
                  |> put_flash(
                    :success,
                    "User activated successfully. User should now be in the main list.")
                {:noreply, socket}

              {:error, %Ecto.Changeset{} = changeset} ->
                socket =
                  socket
                  |> put_flash(:error, "User not activated")

                {:noreply, assign(socket, :changeset, changeset)}
            end
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

  # back from :display - on :search when existing users found
  defp save_user(socket, :insert, user_params) do
    IO.inspect(socket.assigns, label: "save_user :insert")
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
             |> put_flash(:info, "User created successfully")
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
  # defp save_user(socket, :new, user_params) do
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
                # send msg data to parent & redirect
                if send_existing_users_update?(user_changeset, socket) do
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

  @doc """
  Lookup user by field
  - search users by fields; does direct queries only; is not a search, only queries by exact match ILIKE
  ; returns list of users or []
  - loop from end of list user_search_fields checking each; if none, call func with next
  - if index is 0 end loop
  """
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
          lookup_user_direct(user_struct, list_index - 1,organization_id )
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
             Routes.user_index_path(
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
  # defp _fake_save_user(socket, :new, _user_params) do
  #   current_employee = socket.assigns[:current_employee]

  #   user_params = %{
  #     first_name: "Joe3",
  #     last_name: "Schmoe",
  #     email: "joe3@schmoe.com",
  #     phone: "7771213151",
  #     alert_format_set: "sms",
  #     health_card_num: 9999,
  #     date_of_birth: Date.from_iso8601!("1900-01-03")
  #   }

  #   organization =
  #     TurnStile.Company.get_organization(current_employee.current_organization_login_id)

  #   changeset = Patients.create_user(user_params)

  #   case Patients.build_user_changeset_w_assocs(changeset, current_employee, organization) do
  #     %Ecto.Changeset{} = user_changeset ->
  #       # send msg data to parent & redirect
  #       IO.inspect(user_changeset, label: "fake user changeset")

  #       if send_existing_users_update?(user_changeset, socket) do
  #         {:noreply, socket}
  #       else
  #         case Patients.insert_user_changeset(user_changeset) do
  #           {:ok, _user} ->
  #             {:noreply,
  #              socket
  #              |> put_flash(:info, "User created successfully")
  #              |> push_redirect(to: socket.assigns.return_to)}

  #           {:error, %Ecto.Changeset{} = changeset} ->
  #             socket =
  #               socket
  #               |> put_flash(:error, "User not created")

  #             {:noreply, assign(socket, :changeset, changeset)}
  #         end
  #       end

  #     # build_user_changeset_w_assocs not a User
  #     _ ->
  #       socket =
  #         socket
  #         |> put_flash(:error, "User not created: An error occured during creation")

  #       {:noreply, socket}
  #   end
  # end
end
