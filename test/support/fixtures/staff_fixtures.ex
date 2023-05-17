defmodule TurnStile.StaffFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TurnStile.Staff` context.
  """

  @doc """
  Generate a owner.
  """
  def owner_fixture(attrs \\ %{}) do
    {:ok, owner} =
      attrs
      |> Enum.into(%{
        first_name: "some first_name",
        last_name: "some last_name"
      })
      |> TurnStile.Staff.create_owner()

    owner
  end
end
