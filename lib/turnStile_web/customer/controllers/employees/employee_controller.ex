defmodule TurnStileWeb.EmployeeController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff
  alias TurnStile.Staff.Employee
  import Ecto.Changeset

  # new - removed. Use /empployees/register instead
  def index(conn, _params) do
    organization_id = conn.params["organization_id"]
    if !organization_id do
      conn
      |> put_flash(:error, "An Organization ID error ocurred. Make sure it exists.")
      |> redirect(to: Routes.organization_path(conn, :index))
    end
    employees = Staff.list_employees_by_organization(organization_id)
    # get employees in this org
    render(conn, "index.html", employees: employees, organization_id: organization_id, )
  end


  def create(conn, %{"employee" => employee_params}) do
    case Staff.create_employee(employee_params) do
      {:ok, employee} ->
        conn
        |> put_flash(:info, "Employee created successfully.")
        |> redirect(to: Routes.employee_path(conn, :show, employee))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    employee = Staff.get_employee!(id)
    render(conn, "show.html", employee: employee)
  end

  def edit(conn, %{"id" => id}) do
    # IO.inspect("HERE")
    employee = Staff.get_employee!(id)
    # IO.inspect(employee.hashed_password)
    changeset = Staff.change_employee(employee)
    changeset = Map.put(changeset, :action, Routes.organization_employee_path(conn, :create, employee.organization_id, employee_id: employee.id))
    # IO.inspect("ZZZZ")
    # IO.inspect(changeset)
    # exit(:shutdown)
    conn
    # |> Map.put(:action, Routes.organization_employee_path(conn, :create, employee.organization_id, employee_id: employee.id))
    |> render("edit.html", changeset: changeset, employee: employee, organization_id: employee.organization_id)
  end

  def update(conn, %{"id" => id, "employee" => employee_params}) do
    IO.inspect(employee_params)
    employee_params = for {key, val} <- employee_params, into: %{}, do: {String.to_atom(key), val}
    # look up employee - could also use session
    employee = Staff.get_employee!(id)
    #make new empoyee obj - use struct func
    # employee_changed = struct(%Employee{}, employee_params)
    # change takes schema and map here
    changes = change(employee, employee_params)
    IO.inspect(changes)
    # IO.inspect(employee_changes)
    IO.inspect("xxxxxxxx")

    # changed? = change(employee, employee_changes)
    # IO.inspect(changed?)
    # check which values changed on form - not empty
    changed_params = Map.filter(employee_params, fn {_key, val} -> val != "" end)
    case Staff.update_employee(employee, changed_params) do
      {:ok, employee} ->
        conn
        |> put_flash(:info, "Employee updated successfully.")
        |> redirect(to: Routes.employee_path(conn, :show, employee))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", employee: employee, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    employee = Staff.get_employee!(id)
    {:ok, _employee} = Staff.delete_employee(employee)

    conn
    |> put_flash(:info, "Employee deleted successfully.")
    |> redirect(to: Routes.employee_path(conn, :index))
  end
# takes the form value maps to correct permission role
  def assign_permission_role(conn) do
    current_role = conn.assigns[:current_employee].role

    cond do
      # owner
      current_role === to_string(Enum.at(EmployeeAdminRolesEnum.get_roles, 0))  ->
        to_string(Enum.at(EmployeeAdminRolesEnum.get_roles, 0))
      # employee
      current_role === to_string(Enum.at(EmployeeAdminRolesEnum.get_roles, 1))  ->
        to_string(Enum.at(EmployeeAdminRolesEnum.get_roles, 1))
      # developer
      current_role === to_string(Enum.at(EmployeeAdminRolesEnum.get_roles, 2))  ->
        to_string(Enum.at(EmployeeAdminRolesEnum.get_roles, 2))


    end
  end

  def employee_is_in_organization?(conn, _opts) do
    # organization_id = organization_id = conn.params["id"]
    # check

    conn
    # {:ok, _employee} = Staff.delete_employee(employee)

    # conn
    # |> put_flash(:info, "Employee deleted successfully.")
    # |> redirect(to: Routes.employee_path(conn, :index))
  end
end
