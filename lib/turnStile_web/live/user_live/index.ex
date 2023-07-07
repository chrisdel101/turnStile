defmodule TurnStileWeb.UserLive.Index do
  use TurnStileWeb, :live_view
  alias TurnStile.Patients
  alias TurnStile.Patients.User
  alias TurnStile.Staff
  alias TurnStileWeb.EmployeeAuth
  alias TurnStileWeb.AlertUtils
  alias TurnStile.Alerts
  alias TurnStile.Alerts.Alert

  @impl true
  def mount(_params, session, socket) do
    # TODO - cannot be null
    # get token from session
    employee_token = session["employee_token"]
    # use to get logged in user
    current_employee = Staff.get_employee_by_session_token(employee_token)
    organization_id = current_employee.current_organization_login_id

    {:ok,
     assign(
       socket,
       users:  Patients.list_active_users(organization_id),
       current_employee: current_employee
     )}
  end

  @impl true
  # called on index when no user_id
  def handle_params(%{"panel" => panel} = params, _url, socket) do
    # IO.inspect(params, label: "action on index")
    socket = assign(socket, :panel, panel)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # called on show when user_id
  def handle_params(params, _url, socket) do
    # IO.inspect(params, label: "params on index")
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

#
  @impl true
  def handle_info(param, socket) do
    # IO.inspect(param, label: "user-live handle_info on index")
    # update the list of cards in the socket
    {:noreply, socket}
  end

  @impl true
  def handle_event("send_initial_SMS_alert", values, socket) do
    user_id = values["value"]
    # assign user to socket
    socket = assign(socket, :user, Patients.get_user(user_id))

    sms_attrs =
      Alerts.build_alert_attrs(
        socket.assigns.user,
        AlertCategoryTypesMap.get_alert("INITIAL"),
        AlertFormatTypesMap.get_alert("SMS")
      )

    changeset = Alerts.create_new_alert(%Alert{}, sms_attrs)
    # IO.inspect(changeset, label: "changeset in handle_event")
    case  AlertUtils.handle_save_alert(socket, changeset, %{}) do
      {:ok, alert} ->
        case AlertUtils.send_SMS_alert(alert) do
          {:ok, twilio_msg} ->
            IO.inspect(twilio_msg)
            {
              :noreply,
              socket
              # |> assign(:action, "insert")
              |> put_flash(:success, "Alert sent successfully")
              # |> push_redirect(to: socket.assigns.return_to)
            }
          # handle twilio errors
          {:error, error_map, error_code} ->
            {
              :noreply,
              socket
              # |> assign(:action, "insert")
              |> put_flash(:error, "Failure in alert send. #{error_map["message"]}. Code: #{error_code}")
              # |> push_redirect(to: socket.assigns.return_to)
            }
          {:error, error} ->
            {
              :noreply,
              socket
              # |> assign(:action, "insert")
              |> put_flash(:error, "Failure in alert send. #{error}")
              # |> push_redirect(to: socket.assigns.return_to)
            }
          end
      {:error, error} ->
        IO.inspect(error, label: "error in initial alert send")
        socket =
          socket
          |> put_flash(:error, "Initial SMS alert failed to send #{error}")
          {:noreply, socket}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    current_employee = socket.assigns.current_employee

    if EmployeeAuth.has_user_delete_permissions?(socket, current_employee) do
      user = Patients.get_user(id)
      {:ok, _} = Patients.delete_user(user)

      socket =
        socket
        |> put_flash(:info, "User deleted successfully.")
        {:noreply, assign(socket, :users,  Patients.list_active_users(current_employee.current_organization_login_id))}
    else
      socket =
        socket
        |> put_flash(:error, "Insuffient permissions to perform user delete")
        {:noreply, assign(socket, :users,  Patients.list_active_users(current_employee.current_organization_login_id))}
    end
  end

  def handle_event("remove", %{"id" => id}, socket) do
    current_employee = socket.assigns.current_employee

    if EmployeeAuth.has_user_remove_permissions?(socket, current_employee) do
      user = Patients.get_user(id)
      Patients.deactivate_user(user)

      socket =
        socket
        |> put_flash(:info, "User inactivated.")
        {:noreply, assign(socket, :users,  Patients.list_active_users(current_employee.current_organization_login_id))}
    else
      socket =
        socket
        |> put_flash(:error, "Insuffient permissions to perform user remove")
        {:noreply, assign(socket, :users,  Patients.list_active_users(current_employee.current_organization_login_id))}
    end

  end

  defp apply_action(socket, :alerts, params) do
    %{"id" => user_id} = params
    # IO.inspect(Patients.get_user(user_id), label: "user_id")
    socket
    |> assign(:page_title, "User Alerts")
    |> assign(:user, Patients.get_user(user_id))
  end

  defp apply_action(socket, :edit_all, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Patients.get_user(id))
  end
  # assigns individual user changset on :new
  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    # IO.inspect("index", label: "apply_action on index")
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

end
