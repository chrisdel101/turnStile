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
        email: "some@email.com",
        slug: "some-name",
        name: "some name",
        phone: "some phone"
      })
      |> TurnStile.Company.insert_and_preload_organization()

    organization
  end
end
