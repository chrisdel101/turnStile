defmodule TurnStileWeb.UserLive.Show do
  use TurnStileWeb, :live_view

  alias TurnStile.Patients

  @impl true
  def mount(params, session, socket) do
    # IO.inspect(params)

    # get token from session
    employee_token = session["employee_token"]
    # use to get logged in user
    current_employee = TurnStile.Staff.get_employee_by_session_token(employee_token)
    # IO.inspect(socket, label: "sss")

    {:ok,
     assign(
       socket,
       current_employee: current_employee,
     )}
  end


  @impl true
  def handle_params(%{"employee_id" => employee_id, "organization_id" => organization_id, "id" => user_id}, _, socket) do
    IO.puts("HERE2")
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:user, Patients.get_user!(user_id))
     |> assign(employee_id: employee_id, organization_id: organization_id)}
  end

  defp page_title(:show), do: "Show User"
  defp page_title(:edit), do: "Edit User"
end
