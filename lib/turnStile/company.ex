defmodule TurnStile.Company do
  @moduledoc """
  The Company context.
  """

  import Ecto.Query, warn: false
  alias TurnStile.Repo

  alias TurnStile.Company.Organization
  alias TurnStile.Administration.Admin

  @doc """
  Returns the list of organizations.

  ## Examples

      iex> list_organizations()
      [%Organization{}, ...]

  """
  def list_organizations do
    Repo.all(Organization)
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
    TurnStile.Repo.get_by(TurnStile.Company.Organization, slug: slug)
  end
  @doc """
  Creates a organization.

  ## Examples

      iex> create_organization(%{field: value})
      {:ok, %Organization{}}

      iex> create_organization(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_organization(attrs \\ %{}) do
    %Organization{}
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
    Organization.changeset(organization, attrs)
  end

  # utilitites
  def check_organization_has_admins(id) do
    q = from a in Admin,
     where: a.organization_id == ^id,
     select: a.id
    Repo.all(q)
  end

  def check_organization_exists_by_id(id) do
    q = from o in Organization,
     where: o.id == ^id
    #  select:
    x = Repo.all(q)
    IO.inspect('ORGANIZATION EXISTS?')
    IO.inspect(x)
  end

  def check_organization_exists_by_slug(slug) do
    q = from o in Organization,
     where: o.slug == ^slug
    #  select:
    x = Repo.all(q)
    IO.inspect('ORGANIZATION EXISTS?')
    IO.inspect(x)
  end
end
