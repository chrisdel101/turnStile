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
  def get_organization(id, preload? \\ false) do
    query = from(o in Organization, where: o.id == ^id)

    query =
      if preload? do
        query |> Ecto.Query.preload([:employees, :roles, :users])
      else
        query
      end

    Repo.one(query)
  end

  def get_organization_by_name(slug) do
    if not is_nil(slug) do
      query = from o in Organization, where: o.slug == ^slug
      orgs = TurnStile.Repo.all(query)
      cond do
        # return most recent one
        length(orgs) > 1 ->
          List.last(orgs)
      # return only recent
        length(orgs) === 1 ->
          hd(orgs)
      # safely check in case no list returned
        true ->
          nil
      end
      # TurnStile.Repo.get_by(TurnStile.Company.Organization, slug: slug)
    end
  end

  @doc """
  Creates a organization.

  # Creating an organization with owner_employee.
  -build employee with params
  -build organization with params
  ## Examples

      iex> insert_and_preload_organization(%{field: value})
      {:ok, %Organization{}}

      iex> insert_and_preload_organization(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def insert_and_preload_organization(attrs \\ %{}) do
    org_changeset = Organization.changeset(%Organization{}, attrs)
    IO.inspect("insert_and_preload_organization")
    IO.inspect(org_changeset)
    case Repo.insert(org_changeset) do
      {:ok, new_org} ->
        org_preload =
          new_org
        |> Repo.preload(:employees)
        |> Repo.preload(:roles)
        |> Repo.preload(:users)
        # IO.inspect(org_preload)
        {:ok, org_preload}

      {:error, error} ->
        # IO.inspect("ERROR insert_and_preload_organization")
        # IO.inspect(error)
        {:error, error}
    end
  end

  # handle the many-many for new employee- on create
  def update_employee_assoc(organization_struct, employee_params) do
    # IO.inspect("organization_struct")

    # organization_struct = Repo.preload(organization_struct, :employees)
    # load employee on organization
    org_changeset = Ecto.Changeset.change(organization_struct)
    # put_assoc employee/organization
    org_with_emps =
      org_changeset
      |> Ecto.Changeset.put_assoc( :employees, [
        employee_params | organization_struct.employees
      ])

    # IO.inspect("org_with_emps")
    # IO.inspect(org_with_emps)

    case TurnStile.Company.update_organization_changeset(org_with_emps) do
      {:ok, updated_org} ->
        {:ok, updated_org}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Updates a organization. Builds changeset within

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

  # same as above but takes a formed struct
  def update_organization(organization) do
    u_organization = Ecto.Changeset.change(organization)
    Repo.update(u_organization)
  end

  # takes a formed changeset and updates table
  def update_organization_changeset(org_changeset) do
    TurnStile.Repo.update(org_changeset)
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
  def check_organization_has_employees(id) do
    q =
      from a in Employee,
        where: a.organization_id == ^id,
        select: a.id

    Repo.all(q)
  end

  def check_organization_exists_by_id(id) do
    if not is_nil(id) do
      q =
        from o in Organization,
          where: o.id == ^id

      #  select:
      Repo.one(q)
    else
      []
    end
  end

  def check_organization_exists_by_slug(slug) do
    if not is_nil(slug) do
      q =
        from o in Organization,
          where: o.slug == ^slug

      #  select:
      Repo.all(q)
    else
      []
    end
  end

  # check if org has employee members
  def organization_has_members?(id) do
    # members? = Company.check_organization_has_employees(id)
    members? = TurnStile.Staff.list_employee_ids_by_organization(id)

    if !members? or length(members?) === 0 do
      false
    else
      true
    end
  end
end
