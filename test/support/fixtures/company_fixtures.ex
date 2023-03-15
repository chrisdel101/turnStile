defmodule TurnStile.CompanyFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TurnStile.Company` context.
  """

  @doc """
  Generate a organization.
  """
  def organization_fixture(attrs \\ %{}) do
    {:ok, organization} =
      attrs
      |> Enum.into(%{
        email: "some email",
        name: "some name",
        phone: "some phone"
      })
      |> TurnStile.Company.create_organization()

    organization
  end
end
