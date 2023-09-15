defmodule TurnStile.Queue do
  use GenServer
  alias TurnStile.Patients.User
  # client

  # call with client APIs with server name in app code, not pid

  def start_link(default) when is_binary(default) do
    GenServer.start_link(__MODULE__, default, name: :action_server)
  end

  # add item to front of queue
  defp unshift(pid, element) do
    GenServer.call(pid, {:unshift, element})
  end

  # remove item from front of queue
  defp shift(pid, element) do
    GenServer.call(pid, {:unshift, element})
  end

  # add item to end of queue
  defp push(pid, element) do
    GenServer.call(pid, {:push, element})
  end

  def print_all(pid) do
    GenServer.call(pid, :print_all)
  end


  def delete(pid, user) do
    GenServer.call(pid, {:delete, user})
  end

  def delete_all(pid) do
    GenServer.cast(pid, {:delete_all, nil})
  end

  defp lookup(pid, user_id) do
    GenServer.call(pid, {:lookup, user_id})
  end

  def add(pid, user) do
    case lookup(pid, user.id) do
      # user is not in list yet
      nil ->
        with :ok <- push(pid, user) do
          {:ok, user}
        end
        # user already exists
      %User{} = _user ->
        msg = "INFO: Cannot add user to state. User already exists in"
        # IO.puts(msg)
        {:error, msg}
    end
  end

  # Server

  @impl true
  def init(_start_string) do
    schedule_work()
    {:ok, []}
  end

  @impl true # syncrounous
  def handle_call({:unshift, element}, _from, state) do
    new_state = [element | state]
    {:reply, :ok, new_state}
  end

  def handle_call({:push, element}, _from, state) do
    new_state = [state | element]
    {:reply, :ok, new_state}
  end

  # just prints the list
  def handle_call(:print_all, _from, state) do
    {:reply, state, state}
  end

  # check if user in list
  def handle_call({:lookup, user_id}, _from, state) do
    found_user = Enum.find(state, fn user -> user.id === user_id end)
    {:reply, found_user, state}
  end
  # delete user from the list
  # List.delete doesn't work
  def handle_call({:delete, user}, _from, state) do
    # elixirforum.com/t/delete-map-from-list-of-maps-where-we-dont-care-about-map-value-for-some-key/16271
    new_state = Enum.reject(state, fn u -> u.id === user.id end)
    {:reply, :ok, new_state}
  end

  @impl true # asyncrounous
  def handle_cast({:delete_all, nil}, _state) do
    new_state = []
    {:noreply,  new_state}
  end

  @impl true
  def handle_info(:work, state) do
    # Do the desired work here
    # ...

    # Reschedule once more
    schedule_work()

    {:noreply, state}
  end

  defp schedule_work do
    # We schedule the work to happen in 2 hours (written in milliseconds).
    # Alternatively, one might write :timer.hours(2)
    # Process.send_after(self(), :work, 2 * 60 * 60 * 1000)
  end
end
