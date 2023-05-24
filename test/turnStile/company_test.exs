defmodule TurnStile.CompanyTest do
  use TurnStile.DataCase

  alias TurnStile.Company

  describe "organizations" do
    alias TurnStile.Company.Organization

    import TurnStile.CompanyFixtures

    @invalid_attrs %{email: nil, name: nil, phone: nil}

    test "list_organizations/0 returns all organizations" do
      organization = organization_fixture()
      assert Company.list_organizations() == [organization]
    end

    test "get_organization/1 returns the organization with given id" do
      organization = organization_fixture()
      assert Company.get_organization(organization.id) == organization
    end

    test "create_and_preload_organization/1 with valid data creates a organization" do
      valid_attrs = %{email: "some email", name: "some name", phone: "some phone"}

      assert {:ok, %Organization{} = organization} = Company.create_and_preload_organization(valid_attrs)
      assert organization.email == "some email"
      assert organization.name == "some name"
      assert organization.phone == "some phone"
    end

    test "create_and_preload_organization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Company.create_and_preload_organization(@invalid_attrs)
    end

    test "update_organization/2 with valid data updates the organization" do
      organization = organization_fixture()
      update_attrs = %{email: "some updated email", name: "some updated name", phone: "some updated phone"}

      assert {:ok, %Organization{} = organization} = Company.update_organization(organization, update_attrs)
      assert organization.email == "some updated email"
      assert organization.name == "some updated name"
      assert organization.phone == "some updated phone"
    end

    test "update_organization/2 with invalid data returns error changeset" do
      organization = organization_fixture()
      assert {:error, %Ecto.Changeset{}} = Company.update_organization(organization, @invalid_attrs)
      assert organization == Company.get_organization(organization.id)
    end

    test "delete_organization/1 deletes the organization" do
      organization = organization_fixture()
      assert {:ok, %Organization{}} = Company.delete_organization(organization)
      assert_raise Ecto.NoResultsError, fn -> Company.get_organization(organization.id) end
    end

    test "change_organization/1 returns a organization changeset" do
      organization = organization_fixture()
      assert %Ecto.Changeset{} = Company.change_organization(organization)
    end
  end
end
