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
    split_names_list = String.split(input_value)
    # after 2 words will be discarded
    name1 = hd split_names_list
    name2 = Enum.at(split_names_list, 1)
    IO.inspect(name2, label: "name2")
    users = Patients.search_users_by_name(name1, name2)
    # IO.inspect(users, label: "users UP")
    if Enum.empty?(users) do
      # try flipping the names
      users = Patients.search_users_by_name(name2, name1)
      # IO.inspect(users, label: "users IN")
    else
     users
    #  IO.inspect(users, label: "users IN")
    end
  end
end
