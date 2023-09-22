defmodule TurnStile.UserQueueTest do
  alias TurnStile.Patients.User
  use TurnStile.DataCase
  import TurnStile.PatientsFixtures
  alias TurnStile.UserQueue


  test "add item to queue" do
    user = patient_fixture()
    assert UserQueue.add_user(:user_queue, user) == {:ok, user}
    #empty queue
    UserQueue.empty_queue_sync(:user_queue)
  end

  test "add two item to queue" do
    users = patients_fixture()
    Enum.each(users, fn user ->
     UserQueue.add_user(:user_queue, user)
    end)
    assert UserQueue.count(:user_queue) == 2
    # empty queue
    UserQueue.empty_queue_sync(:user_queue)
  end

  test "lookup_user item in queue" do
    user = patient_fixture()
    UserQueue.add_user(:user_queue, user)
    assert UserQueue.lookup_user(:user_queue, user) == user
  end

end
