defmodule TurnStile.PatientsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TurnStile.Patients` context.
  """

  def patient_fixture(attrs \\ %{}) do
    user_changeset =
      attrs
      |> Enum.into(%{
        email: "some@email.com",
        first_name: "some first_name",
        health_card_num: 42,
        last_name: "some last_name",
        phone: "some phone"
      })
      |> TurnStile.Patients.create_user()
    Ecto.Changeset.apply_changes(user_changeset)
  end
  # list of patients
  def patients_fixture(attrs \\ %{}) do
    user1_changeset =
      attrs
      |> Enum.into(%{
        email: "some@email,com",
        first_name: "some first_name",
        health_card_num: 42,
        last_name: "some last_name",
        phone: "some phone"
      })
      |> TurnStile.Patients.create_user()
    user2_changeset =
      attrs
      |> Enum.into(%{
        email: "some_other@email.com",
        first_name: "some other first_name",
        health_card_num: 421,
        last_name: "some other last_name",
        phone: "some other phone"
      })
      |> TurnStile.Patients.create_user()
    [Ecto.Changeset.apply_changes(user1_changeset), Ecto.Changeset.apply_changes(user2_changeset)]
  end
end
