defmodule TurnStile.PatientsTest do
  use TurnStile.DataCase

  alias TurnStile.Patients

  describe "users" do
    alias TurnStile.Patients.User

    import TurnStile.PatientsFixtures

    @invalid_attrs %{email: nil, first_name: nil, health_card_num: nil, last_name: nil, phone: nil}

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Patients.list_users() == [user]
    end

    test "get_user/1 returns the user with given id" do
      user = user_fixture()
      assert Patients.get_user(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{email: "some email", first_name: "some first_name", health_card_num: 42, last_name: "some last_name", phone: "some phone"}

      assert {:ok, %User{} = user} = Patients.create_user(valid_attrs)
      assert user.email == "some email"
      assert user.first_name == "some first_name"
      assert user.health_card_num == 42
      assert user.last_name == "some last_name"
      assert user.phone == "some phone"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Patients.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      update_attrs = %{email: "some updated email", first_name: "some updated first_name", health_card_num: 43, last_name: "some updated last_name", phone: "some updated phone"}

      assert {:ok, %User{} = user} = Patients.update_user(user, update_attrs)
      assert user.email == "some updated email"
      assert user.first_name == "some updated first_name"
      assert user.health_card_num == 43
      assert user.last_name == "some updated last_name"
      assert user.phone == "some updated phone"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Patients.update_user(user, @invalid_attrs)
      assert user == Patients.get_user(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Patients.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Patients.get_user(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Patients.change_user(user)
    end
  end
end
