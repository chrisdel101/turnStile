defmodule TurnStileWeb.UserLive.UpsertFormComponent do
  # handles the logic for the modals
  use TurnStileWeb, :live_component

  alias TurnStileWeb.EmployeeAuth
  alias TurnStile.Patients

  @impl true
  def update(%{user: user} = assigns, socket) do
    changeset = Patients.change_user(user)
    # IO.inspect(changeset, label: "changeset")
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  # def handle_event(param1, %{"user" => user_params}, socket) do
  #   changeset =
  #     socket.assigns.user
  #     |> Patients.change_user(user_params)
  #     |> Map.put(:action, :validate)

  #   {:noreply, assign(socket, :changeset, changeset)}
  # end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Patients.change_user(user_params)
      |> Map.put(:action, :validate)

    IO.inspect("changeset", label: "VALIDATE")

    {:noreply, assign(socket, :changeset, changeset)}
  end

  # handle save for new and edit
  def handle_event("save", %{"user" => user_params}, socket) do
    current_employee = socket.assigns[:current_employee]
    # IO.inspect(socket, label: "action")
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

  # index edit form
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

  # show edit form
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

  defp save_user(socket, :new, user_params) do
    current_employee = socket.assigns[:current_employee]
    # IO.inspect(user_params, label: "user_params: save_user")

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
end
