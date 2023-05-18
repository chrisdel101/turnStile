defmodule TurnStile.Company do
  @moduledoc """
  The Company context.
  """

  import Ecto.Query, warn: false
  alias TurnStile.Repo

  alias TurnStile.Company.Organization
  alias TurnStile.Staff.Employee

  @doc """
  Returns the list of organizations.

  ## Examples

      iex> list_organizations()
      [%Organization{}, ...]

  """
  def list_organizations do
    query = from o in Organization,
    select: %{o | owner_employee: nil}
    Repo.all(query)
  end

  @doc """
  Gets a single organization.

  Raises `Ecto.NoResultsError` if the Organization does not exist.

  ## Examples

      iex> get_organization(123)
      %Organization{}

      iex> get_organization(456)
      ** (Ecto.NoResultsError)

  """
  def get_organization(id)  do
     Repo.get(Organization, id)
  end


  def get_organization_by_name(slug) do
    if not is_nil(slug) do
      TurnStile.Repo.get_by(TurnStile.Company.Organization, slug: slug)
    end
  end
  @doc """
  Creates a organization.

  # Creating an organization with owner_employee.
  - build employee with params
  - build organization with params
  ## Examples

      iex> create_organization(%{field: value})
      {:ok, %Organization{}}

      iex> create_organization(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_organization(attrs \\ %{} ) do
    %Organization{}
    # # extract owner_employee params
    %{"owner_employee" => map} = attrs["organization"]


    org_attrs = Map.take(attrs["organization"], ["name", "phone", "email", "slug"])

    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a organization.

  ## Examples

      iex> update_organization(organization, %{field: new_value})
      {:ok, %Organization{}}

      iex> update_organization(organization, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_organization(%Organization{} = organization, attrs) do
    organization
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a organization.

  ## Examples

      iex> delete_organization(organization)
      {:ok, %Organization{}}

      iex> delete_organization(organization)
      {:error, %Ecto.Changeset{}}

  """
  def delete_organization(%Organization{} = organization) do
    Repo.delete(organization)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organization changes.

  ## Examples

      iex> change_organization(organization)
      %Ecto.Changeset{data: %Organization{}}

  """
  def change_organization(%Organization{} = organization, attrs \\ %{}) do
    Organization.form_changeset(organization, attrs)
  end

  # utilitites
  def check_organization_has_employees(id) do
    q = from a in Employee,
     where: a.organization_id == ^id,
     select: a.id
    Repo.all(q)
  end

  def check_organization_exists_by_id(id) do
    q = from o in Organization,
     where: o.id == ^id,
     select: %{o | owner_employee: nil}
    #  select:
    Repo.all(q)
  end

  def check_organization_exists_by_slug(slug) do
    if not is_nil(slug) do
      q = from o in Organization,
       where: o.slug == ^slug,
       select: %{o | owner_employee: nil}
      #  select:
      Repo.all(q)
    else
      []
    end
  end
end
