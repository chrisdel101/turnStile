defmodule TurnStileWeb.UserLive.DisplayUsersList do
  use TurnStileWeb, :live_component

  @test_users [%TurnStile.Patients.User{
    id: 13,
    email: "arssonist@yahoo.com",
    first_name: "Joe",
    health_card_num: 99991122,
    last_name: "Schmoe69",
    phone: "3065190138",
    date_of_birth: ~D[1900-01-01],
    is_active?: true,
    user_alert_status: "pending",
    alert_format_set: "email",
    employee_id: 1,
    account_confirmed_at: nil,
    activated_at: ~N[2023-08-28 00:39:25],
    deactivated_at: nil,
    inserted_at: ~N[2023-08-28 19:24:03],
    updated_at: ~N[2023-08-28 22:05:32]
  },
 %TurnStile.Patients.User{
    id: 1,
    email: "arssonist@yahoo.com",
    first_name: "Joe",
    health_card_num: 9999,
    last_name: "Schmoe",
    phone: "3065190138",
    date_of_birth: ~D[1900-01-01],
    is_active?: true,
    user_alert_status: "confirmed",
    alert_format_set: "email",
    employee_id: 1,
    account_confirmed_at: nil,
    activated_at: ~N[2023-08-25 18:42:02],
    deactivated_at: nil,
    inserted_at: ~N[2023-08-25 18:43:45],
    updated_at: ~N[2023-08-28 17:40:21]
  }]

  @impl true
  def update(props, socket) do
    # IO.inspect(props, label: "display_component props")
    # IO.inspect(props.action, label: "display_component action")
    current_employee = props.current_employee
    # IO.inspect(props.action, label: "display_component action")
    organization = TurnStile.Company.get_organization(current_employee.current_organization_login_id)
    {:ok,
     socket
     |> assign(props)
     |> assign(:organization, organization)
    #  |> assign(:users, @test_users)
    }
  end


  @impl true
  # click on user in search form
  def handle_event("select-inactive-user", %{"user_id" => user_id}, socket) do
    current_employee = socket.assigns.current_employee
    # redirect to :new form
    {:noreply, push_patch(socket, to: Routes.user_index_path(socket, :select, current_employee.current_organization_login_id, current_employee.id, user_id: user_id))}
  end
  def handle_event("select-active-user", %{"user_id" => _user_id}, socket) do

   {:noreply,
   socket
   |> put_flash(:warning, "ERROR: This user is aleady active. You cannot select an already activated user. This user should alredy be in the main list. Look through your list of users again.")}
  end
  # when exising users found, to back to original user form
  def handle_event("custom-back", unsigned_params, socket) do
    current_employee = socket.assigns.current_employee
    handle_send_data(unsigned_params, socket)
    {:noreply, push_patch(socket, to: Routes.user_index_path(socket, :display_existing_users, current_employee.current_organization_login_id, current_employee.id))}
    {:noreply, socket}
  end
  def handle_event("handle_display_click",  %{"display_type" => display_type, "user_id" => user_id, "is_active?" => is_active?}, socket) do
    # IO.inspect(is_active?, label: "handle_display_click")
    cond do
      display_type === DisplayListComponentTypesMap.get_type("FOUND_USERS_LIST") ->
        if is_active? == "true" do
          IO.inspect(is_active?, label: "handle_display_click")
          {:noreply,
          socket
          |> put_flash(:warning, "ERROR: This user is aleady active. You cannot select an already activated user. This user should alredy be in the main list. Look through your list of users again.")}
        else
          current_employee = socket.assigns.current_employee
          # redirect to :new form
          {:noreply, push_patch(socket, to: Routes.user_index_path(socket, :select, current_employee.current_organization_login_id, current_employee.id, user_id: user_id))}
        end
      true ->
        IO.puts("Invalid display type in handle_event:handle_display_click")
        {:noreply, socket}
    end
  end
  # send msg back to index handle_msg
  defp handle_send_data(_unsigned_params, socket) do
    current_employee = socket.assigns[:current_employee]
    user_changeset = socket.assigns[:user_changeset]
    IO.inspect(user_changeset, label: "handle_send_data")

    send(self(),
    {:reject_existing_users,
    %{user_changeset: user_changeset,
      redirect_to: Routes.user_index_path(socket, :insert, current_employee.current_organization_login_id, current_employee.id)}})
  end


end
