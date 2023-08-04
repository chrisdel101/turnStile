defmodule TurnStileWeb.SearchLive.Search do
  use TurnStileWeb, :live_component
  alias TurnStile.Patients

  @json TurnStile.Utils.read_json("alert_text.json")

  @impl true
  def update(props, socket) do
    {:ok,
     socket
     |> assign(props)
     |> assign(:json, @json)
     |> assign(:users, [])}
  end

  @impl true
  def handle_event("validate", %{"search" => %{"user_name_input" => user_name_input}}, socket) do
    IO.inspect(user_name_input, label: "user_name_input")
    {:noreply, socket}
  end

  def handle_event("select_user", %{"user_id" => user_id}, socket) do
    IO.inspect(user_id, label: "USER")
    {:noreply, socket}
  end

def handle_event("inc", %{"myvar1" => "val1", "myvar2" => "val2"}, socket) do
  IO.inspect("INC", label: "params")
    {:noreply, socket}
  end

  def handle_event("save", %{"search" => %{"user_name_input" => user_name_input}}, socket) do
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
      users = handle_user_search(user_name_input)
      {:noreply, assign(socket, :users, users)}
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
    # search by first/last name
    users = Patients.search_users_by_last_and_first_name(name1, name2)
    # IO.inspect(users, label: "users UP")
    # if no results using first/last name
    if Enum.empty?(users) do
      cond do
        # if name2 is not empty
        !is_nil(name2) && name2 !== "" ->
        # try flipping the names last/first name and run again
          users = Patients.search_users_by_last_and_first_name(name2, name1)
        is_nil(name2) || name2 == "" ->
          # if name2 is empty, search name1 for first name
          users = Patients.search_users_by_first_name(name1)
        true ->
          []
      end
    else
     users
    end
  end
end
