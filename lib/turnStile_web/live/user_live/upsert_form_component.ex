defmodule TurnStileWeb.UserLive.UpsertFormComponent do
  # handles the logic for the modals
  use TurnStileWeb, :live_component

  alias TurnStileWeb.EmployeeAuth
  alias TurnStile.Patients

  @impl true
  # empty user struct getting passed as props; see index apply_action(:new)
  def update(%{user: user} = assigns, socket) do
    IO.inspect(assigns, label: "assigns")
    # build default user changeset
    changeset = Patients.change_user(user)
    # IO.inspect(changeset, label: "changeset")
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    IO.inspect(socket.assigns.changeset, label: "changeset")
    IO.inspect(user_params, label: "user_params")
    changeset =
      socket.assigns.user
      |> Patients.change_user(user_params)
      |> Map.put(:action, :validate)

      # changeset = validate_choose_alert_type_field(changeset)
      IO.inspect(changeset, label: "VALIDATE")
    {:noreply, assign(socket, :changeset, changeset)}
  end

  # only fires on change- handles changing the form based on radio button selection
  def handle_event("radio_click", %{"user" => %{"alert_format_set" => alert_format}}, socket) do

    IO.inspect(socket.assigns.changeset, label: "radio_click")
    IO.inspect(alert_format, label: "radio_click")

    # # check for changes when radio click
    if alert_format && Map.has_key?(socket.assigns.changeset, :data) do
      # IO.inspect(alert_params, label: "alert_params")
      # check which type of alert to change
      cond do
        # radio - flip to email form
        alert_format === AlertFormatTypesMap.get_alert("EMAIL") ->

          # IO.inspect(socket.assigns.changeset, label: "click HERE radio")

          # sets up changeset for template use
          # changeset =
          #   socket.assigns.changeset
          #   |> Patients.change_user(%{alert_format_set: alert_format})
          changeset = Ecto.Changeset.change(socket.assigns.changeset, alert_format_set: "email")

          # |> Ecto.Changeset.change(alert_format_set: "email")


          IO.inspect(changeset, label: "changeset radio email")

          {:noreply, assign(socket, :changeset, changeset)}

        # end
        alert_format === AlertFormatTypesMap.get_alert("SMS") ->
          IO.inspect(alert_format, label: "SMS")

          changeset = Ecto.Changeset.change(socket.assigns.changeset, alert_format_set: "sms")
          IO.inspect(changeset, label: "changeset radio SMS")

          {:noreply, assign(socket, :changeset, changeset)}

        #  end
        true ->
          IO.puts("NO keys")
          {:noreply, socket}
      end
    end
  end

  # handle save for new and edit
  def handle_event("save", %{"user" => user_params}, socket) do
    current_employee = socket.assigns[:current_employee]
    IO.inspect(socket.assigns, label: "action")
    # no submit if validation errors
    if !socket.assigns.changeset.valid? do
      handle_event("validate", %{"user" => user_params}, socket)
    else
      case socket.assigns.action do
        # :edit_all is edit button on index page - not shown curently
        action when action in [:edit, :edit_all] ->
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
    IO.inspect(user_params, label: "user_params: save_user")

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

            case Patients.create_user_w_assocs2(current_employee, user_params) do
              {:ok, user} ->
                case Patients.insert_user(user) do
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

              {:error, error} ->
                socket =
                  socket
                  |> put_flash(:error, "User not created: #{error}")

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

  # edit from index - not currently used
  defp save_user(socket, :edit_all, user_params) do
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

  defp validate_choose_alert_type_field(changeset) do
    # IO.inspect(changeset.data, label: "yyyyy")
    alert_format_changes = Ecto.Changeset.get_change(changeset, :alert_format_set)
    phone_setting = Map.get(changeset.data, :alert_format_set)
    email = Ecto.Changeset.get_change(changeset, :email)
    phone = Ecto.Changeset.get_change(changeset, :phone)
    # IO.inspect(changeset.data, label: "xxxxxxxxxxxxxx")
    # IO.inspect(phone, label: "xxxxxxxxxxxxxx")
    cond do
      # check for email change
      alert_format_changes === AlertFormatTypesMap.get_alert("EMAIL") && is_nil(email) ->
        IO.puts("FIRED1")
        changeset
        # |> Ecto.Changeset.add_error(:email, "Email type is chosen. Must have an email.")
        # Clear errors for phone field when switching to email
      # check for default setting and no email change; needs phone
      alert_format_changes !== AlertFormatTypesMap.get_alert("EMAIL") &&
        is_nil(phone) ->
        IO.puts("FIRED2")
        changeset
        # |> Ecto.Changeset.add_error(:phone, "SMS type is chosen. Must have a phone number.")
      true ->
         IO.puts("FIRED1")
        changeset
    end
  end
end
