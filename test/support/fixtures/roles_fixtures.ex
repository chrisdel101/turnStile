defmodule TurnStile.RolesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TurnStile.Roles` context.
  """

  @doc """
  Generate a role.
  """
  def role_fixture(attrs \\ %{}) do
    {:ok, role} =
      attrs
      |> Enum.into(%{

      })
      |> TurnStile.Roles.create_role()

    role
  end
end
