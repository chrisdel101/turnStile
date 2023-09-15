defmodule TurnStile.UserQueueTest do
  alias TurnStile.Patients.User
  use TurnStile.DataCase
  import TurnStile.PatientsFixtures
  alias TurnStile.UserQueue


  test "add item to queue" do
    user = patient_fixture()
    assert UserQueue.add_user(:user_queue, user) == {:ok, user}
  end

  test "add item to queue" do
    user = patient_fixture()
    assert UserQueue.add_user(:user_queue, user) == {:ok, user}
  end

  test "lookup_user item in queue" do
    user = patient_fixture()
    UserQueue.add_user(:user_queue, user)
    assert UserQueue.lookup_user(:user_queue, user) == user
  end
end
