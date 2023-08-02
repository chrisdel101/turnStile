defmodule TurnStileWeb.SearchLive.Search do
  use TurnStileWeb, :live_component
  @json TurnStile.Utils.read_json("alert_text.json")

  @impl true
  def update(props, socket) do


    {:ok,
     socket
     |> assign(props)
     |> assign(:json, @json)}
  end

  @impl true
  def handle_event("validate", %{"search" => %{"user_name" => user_name}}, socket) do
    IO.inspect(user_name, label: "user_name")
    {:noreply, socket}
  end

  def handle_event("save", %{"search" => %{"user_name" => user_name}}, socket) do
    user_search(user_name)
    {:noreply, socket}
  end

  def user_search(user_name) do
    # slugigy param
    lower_user_name = String.downcase(user_name)
    # check if org name exists

  end
end
