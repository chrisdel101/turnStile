defmodule TurnStileWeb.UserLive.Index do
  use TurnStileWeb, :live_view
  alias TurnStileWeb.AlertController
  alias TurnStile.Patients
  alias TurnStile.Patients.User
  alias TurnStile.Staff
  alias TurnStileWeb.EmployeeAuth
  alias TurnStileWeb.AlertUtils

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
    IO.inspect(param, label: "user-live handle_info on index")
    # update the list of cards in the socket
    {:noreply, socket}
  end

  @impl true
  def handle_event("initial_alert", values, socket) do
    user_id = values["value"]
    current_employee = socket.assigns.current_employee
    if EmployeeAuth.has_alert_send_permissions?(socket, current_employee) do
      socket = AlertUtils.send_alert(socket, %{"employee_id" => current_employee.id, "user_id" => user_id})
      {:noreply, socket}
    else
      socket =
        socket
        |> put_flash(:error, "Insuffient permissions to perform alert send")
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
    IO.inspect("index", label: "apply_action on index")
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

end
