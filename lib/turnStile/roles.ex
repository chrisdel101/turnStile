defmodule TurnStile.Roles do
  @moduledoc """
  The Roles context.
  """

  import Ecto.Query, warn: false
  alias TurnStile.Repo

  alias TurnStile.Roles.Role

  @doc """
  Returns the list of roles.

  ## Examples

      iex> list_roles()
      [%Role{}, ...]

  """
  def list_roles do
    raise "TODO"
  end

  @doc """
  Gets a single role.

  Raises if the Role does not exist.

  ## Examples

      iex> get_role!(123)
      %Role{}

  """
  def get_role(id) do
    Repo.get(Role, id)
  end
  @doc """
  Creates a role.

  ## Examples

      iex> create_role(%{field: value})
      {:ok, %Role{}}

      iex> create_role(%{field: bad_value})
      {:error, ...}

  """
  def create_role(%Role{} = role, attrs \\ %{}) do
    Role.changeset(role, attrs)
  end


  def build_role(attrs) do
    %Role{
      name: attrs[:name] || attrs["name"],
      value: attrs[:value] || attrs["value"]
    }
  end

  @doc """
  Updates a role.

  ## Examples

      iex> update_role(role, %{field: new_value})
      {:ok, %Role{}}

      iex> update_role(role, %{field: bad_value})
      {:error, ...}

  """
  def update_role(%Role{} = role, attrs) do
    raise "TODO"
  end

  @doc """
  Deletes a Role.

  ## Examples

      iex> delete_role(role)
      {:ok, %Role{}}

      iex> delete_role(role)
      {:error, ...}

  """
  def delete_role(%Role{} = role) do
    raise "TODO"
  end

  @doc """
  Returns a data structure for tracking role changes.

  ## Examples

      iex> change_role(role)
      %Todo{...}

  """
  def change_role(%Role{} = role, _attrs \\ %{}) do
    raise "TODO"
  end
end
