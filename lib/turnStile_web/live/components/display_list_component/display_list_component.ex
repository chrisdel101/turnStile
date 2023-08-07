defmodule TurnStileWeb.UserLive.DisplayListComponent do
  use TurnStileWeb, :live_component
  alias TurnStile.Patients

  @impl true
  def update(props, socket) do
    # IO.inspect(props, label: "props")
    {:ok,
     socket
     |> assign(props)
     |> assign(:live_action, props.action)
     |> assign(:users, props.users)}
  end

  @impl true
  # click on user in search form
  def handle_event("select_user", %{"user_id" => user_id}, socket) do
    current_employee = socket.assigns.current_employee
    # redirect to :new form
    {:noreply, push_patch(socket, to: Routes.user_index_path(socket, :insert, current_employee.current_organization_login_id, current_employee.id, user_id: user_id))}
  end

  def handle_event("save", %{"search" => %{"user_name_input" => user_name_input}}, socket) do

  end


end
