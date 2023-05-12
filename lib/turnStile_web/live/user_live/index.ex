defmodule TurnStileWeb.UserLive.Index do
  use TurnStileWeb, :live_view

  alias TurnStileWeb.UserLive.FormComponent
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

    form = %{
      "user_id" => nil
      # organization_id: "",
      # employee_id: ""
    }

    {:ok,
     assign(
       socket,
       form: form,
       users: list_users(),
       current_employee: current_employee,
       trigger_submit: false
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # ("ALERT2")
    # IO.inspIO.putsect(params)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_event("alert_c", values, socket) do
    IO.puts("click")
    IO.inspect(values)
    # IO.inspect(call)
    {:noreply, socket}
  end

  def handle_event("alert_s", values, socket) do
    IO.puts("submit")

    IO.inspect(values)

    # socket = assign(socket, trigger_submit: true)

    {:noreply, socket}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
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
end
