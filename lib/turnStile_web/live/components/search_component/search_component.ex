defmodule TurnStileWeb.UserLive.SearchComponent do
  use TurnStileWeb, :live_component
  alias TurnStile.Patients

  @impl true
  def update(props, socket) do
    # IO.inspect(props, label: "props")
    {:ok,
     socket
     |> assign(props)
     |> assign(:live_action, props.action)}
      end

  @impl true
  def handle_event("validate", %{"search" => %{"user_name_input" => user_name_input}}, socket) do
    IO.inspect(user_name_input, label: "user_name_input")
    {:noreply, socket}
  end
  # click on user in search form
  def handle_event("select_user", %{"user_id" => user_id}, socket) do
    # IO.inspect(user_id, label: "user_id")
    current_employee = socket.assigns.current_employee
    # redirect to :new form
    {:noreply, push_patch(socket, to: Routes.user_index_path(socket, :insert, current_employee.current_organization_login_id, current_employee.id, user_id: user_id))}
  end

  def handle_event("save", %{"search" => %{"user_name_input" => user_name_input}}, socket) do
    # IO.inspect(user_name_input, label: "user_name_input")
    if is_nil(user_name_input) || user_name_input == "" do
      {
        :noreply,
        socket
        |> put_flash(
          :warning,
          "Input cannot be blank"
        )
      }
    else
      existing_users_found = handle_user_search(user_name_input)
      IO.inspect(existing_users_found, label: "search: existing_users_found")
      #send a message with new state to parent
      send(self(), {:users_found,
      %{"existing_users_found" => existing_users_found}})
      {:noreply, assign(socket, :existing_users_found, existing_users_found)}
    end
  end

  # only handles 2 part names for now
  # TODO: rotate thru 2-by-2 checking all names
  def handle_user_search(input_value) do
    # slugigy param
    lower_user_name = String.downcase(input_value)
    split_names_list = String.split(lower_user_name)
    # after 2 words will be discarded
    name1 = hd split_names_list
    name2 = Enum.at(split_names_list, 1)
    # search by last/first name
    users = Patients.search_users_by_last_and_first_name(name1, name2)
    # IO.inspect(users, label: "users UP")
    # if no results using first/last name
    if Enum.empty?(users) do
      cond do
        # if name2 is not empty
        !is_nil(name2) && name2 !== "" ->
        # try flipping the names to last/first name and run again
          Patients.search_users_by_last_and_first_name(name1, name2)
        is_nil(name2) || name2 == "" ->
          # if name2 is empty, search name1 for first name
          Patients.search_users_by_first_name(name1)
        true ->
          []
      end
    else
     users
    end
  end
  # defp maybe_store_search_fields(socket, %{"search_field_name" => search_field_name, "search_field_value" => search_field_value} = props) do
  #   socket
  #   |> assign(:search_field_name, search_field_name)
  #   |> assign(:search_field_value, search_field_value)
  # end
  # defp maybe_store_search_fields(socket, props) do
  #   socket
  # end
end
