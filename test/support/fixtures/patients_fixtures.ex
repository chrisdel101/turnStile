defmodule TurnStile.PatientsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TurnStile.Patients` context.
  """

  def patient_fixture(attrs \\ %{}) do
    user_changeset =
      attrs
      |> Enum.into(%{
        email: "some email",
        first_name: "some first_name",
        health_card_num: 42,
        last_name: "some last_name",
        phone: "some phone"
      })
      |> TurnStile.Patients.create_user()
    Ecto.Changeset.apply_changes(user_changeset)
  end
end
