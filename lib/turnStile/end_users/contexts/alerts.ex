defmodule TurnStile.Alerts do
  @moduledoc """
  The Alerts context.
  """

  import Ecto.Query, warn: false
  alias TurnStile.Repo

  alias TurnStile.Alerts.Alert
  alias TurnStile.Patients
  alias TurnStile.Staff

  @doc """
  Returns the list of alerts.

  ## Examples

      iex> list_alerts()
      [%Alert{}, ...]

  """
  def list_alerts do
    raise "TODO"
  end

  @doc """
  Gets a single alert.

  Raises if the Alert does not exist.

  ## Examples

      iex> get_alert!(123)
      %Alert{}

  """
  def get_alert!(id), do: raise "TODO"


  def get_alerts_for_user(user_id) do
    query = from(a in Alert,
      where: a.user_id == ^user_id,
      order_by: [desc: a.inserted_at]
    )
    Repo.all(query)
  end

  @doc """
  create_new_alert
  Creates a new alert object for use in insertion process.
  """
  def create_new_alert(%Alert{} = alert, attrs \\ %{}) do
    Alert.changeset(alert, attrs)
  end
  @doc """
  create_alert_w_assoc
  Handles creation and insertion into DB.
  """
  def create_alert_w_assoc(employee_id, user_id, attrs) do
    user = Patients.get_user!(user_id)
    employee = Staff.get_employee(employee_id)
    if !user || !employee do
      {:error, "User or Employee not found for alert creation"}
    else
      # build_assoc to both user & employee
      alert_assoc = Ecto.build_assoc(user, :alerts, employee_id: employee.id)
      alert = create_new_alert(alert_assoc, attrs)

      Repo.insert(alert)
    end
  end

  @doc """
  Updates a alert.

  ## Examples

      iex> update_alert(alert, %{field: new_value})
      {:ok, %Alert{}}

      iex> update_alert(alert, %{field: bad_value})
      {:error, ...}

  """
  def update_alert(%Alert{} = alert, attrs) do
    raise "TODO"
  end

  @doc """
  Deletes a Alert.

  ## Examples

      iex> delete_alert(alert)
      {:ok, %Alert{}}

      iex> delete_alert(alert)
      {:error, ...}

  """
  def delete_alert(%Alert{} = alert) do
    raise "TODO"
  end

  @doc """
  Returns a data structure for tracking alert changes.

  ## Examples

      iex> change_alert(alert)
      %Todo{...}

  """
  def change_alert(%Alert{} = alert, _attrs \\ %{}) do
    raise "TODO"
  end
end
