defmodule TurnStileWeb.UserLive.DisplayListComponent do
  use TurnStileWeb, :live_component

  @impl true
  def update(props, socket) do
    # IO.inspect(props, label: "upate fired")
    {:ok,
     socket
     |> assign(props)
     |> assign(:user_changeset, props.user_changeset)
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
  # when exising users found, to back to original user form
  def handle_event("custom-back", unsigned_params, socket) do
    current_employee = socket.assigns.current_employee
    handle_send_data(unsigned_params, socket)
    {:noreply, push_patch(socket, to: Routes.user_index_path(socket, :display, current_employee.current_organization_login_id, current_employee.id))}
    {:noreply, socket}
  end
  # send msg back to index handle_msg
  defp handle_send_data(unsigned_params, socket) do
    current_employee = socket.assigns[:current_employee]
    user_changeset = socket.assigns[:user_changeset]
    # IO.inspect(user_changeset.data, label: "custom-user_changeset in display")

    send(self(),
    {:reject_existing_users,
    %{user_changeset: user_changeset,
      redirect_to: Routes.user_index_path(socket, :insert, current_employee.current_organization_login_id, current_employee.id)}})
  end


end
