defmodule TurnStile.ActionGenServer do
  use GenServer
  alias TurnStile.Patients.User
  # client

  # call with client APIs with server name in app code, not pid

  def start_link(default) when is_binary(default) do
    GenServer.start_link(__MODULE__, default, name: :action_server)
  end

  # add item to front of list
  defp unshift(pid, element) do
    GenServer.cast(pid, {:unshift, element})
  end
  # remove item to front of list
  defp shift(pid) do
    GenServer.call(pid, :shift)
  end

  def print_all(pid) do
    GenServer.call(pid, :print_all)
  end

  def delete_all(pid) do
    GenServer.cast(pid, {:delete_all, nil})
  end
  defp lookup(pid, user_id) do
    GenServer.call(pid, {:lookup, user_id})
  end

  def add_new_user(pid, user) do
    case lookup(pid, user.id) do
      # user is not in list yet
      nil ->
        with :ok <- unshift(pid, user) do
          {:ok, user}
        end
        # user already exists
      %User{} = _user ->
        msg = "INFO: Cannot add user to state. User already exists in"
        IO.puts(msg)
        {:error, msg}
    end
  end

  # Server

  @impl true
  @spec init(any) :: {:ok, []}
  def init(_start_string) do
    schedule_work()
    {:ok, []}
  end

  @impl true
  def handle_call(:shift, _from, state) do
    [to_caller | new_state] = state
    IO.inspect(to_caller, label: "to_caller")
    {:reply, to_caller, new_state}
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

  @impl true
  def handle_cast({:unshift, element}, state) do
    new_state = [element | state]
    {:noreply, new_state}
  end

  def handle_cast({:delete_all, nil}, _state) do
    new_state = []
    {:noreply, new_state}
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
