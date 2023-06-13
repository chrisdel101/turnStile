defmodule TurnStileWeb.UserLive.Index do
  use TurnStileWeb, :live_view
  alias TurnStileWeb.AlertController
  alias TurnStile.Patients
  alias TurnStile.Patients.User
  alias TurnStile.Staff

  @impl true
  def mount(_params, session, socket) do
    # TODO - cannot be null
    # get token from session
    employee_token = session["employee_token"]
    # use to get logged in user
    current_employee = Staff.get_employee_by_session_token(employee_token)
    IO.inspect(socket, label: "sss")

    {:ok,
     assign(
       socket,
       users: list_users(),
       current_employee: current_employee,
       trigger_submit: false,
       notice: "hello"
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    IO.inspect(params, label: "params on index")
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info(param, socket) do
    IO.inspect(param, label: "param22 on index")
    # update the list of cards in the socket
    {:noreply, socket}
  end

  def handle_event("alert", values, socket) do
    user_id = values["value"]
    employee_id = socket.assigns.current_employee.id
    socket = send_alert(socket, %{"employee_id" => employee_id, "user_id" => user_id})
    {:noreply, socket}
  end

  defp apply_action(socket, :edit_all, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Patients.get_user!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Patients.get_user!(id)
    {:ok, _} = Patients.delete_user(user)

    {:noreply, assign(socket, :users, list_users())}
  end

  defp list_users do
    Patients.list_users()
  end

  defp send_alert(socket, %{"employee_id" => employee_id, "user_id" => user_id}) do
    case AlertController.create_live(%{"employee_id" => employee_id, "user_id" => user_id}) do
      {:ok, _twl_msg} ->
        socket =
          socket
          |> put_flash(:info, "Alert sent successfully.")
        socket
      # handle twilio errors
      {:error, error_map, _error_code} ->
        socket =
          socket
          |> put_flash(:error, "Alert Failed: #{error_map["message"]}")
        socket
      true ->
        socket =
          socket
          |> put_flash(:error, "An unknown error occured")
          socket
    end
  end
end
