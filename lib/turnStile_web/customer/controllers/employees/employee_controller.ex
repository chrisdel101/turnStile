defmodule TurnStileWeb.EmployeeController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff

  # def new - removed: Use /employess/register instead

  def index(conn, _params) do
    organization_id = get_session(conn)["current_organization_id_str"] || conn.params["organization_id"]
    if !organization_id do
      conn
      |> put_flash(:error, "An Organization ID error ocurred. Make sure it exists.")
      |> redirect(to: Routes.organization_path(conn, :index))
    end
    # get all employees in the organization by id
    employee_ids = Staff.list_employee_ids_by_organization(TurnStile.Utils.convert_to_int(organization_id))
    # lookup all those ids
    employees = Staff.list_employees_by_ids(employee_ids)
    render(conn, "index.html", employees: employees, organization_id: organization_id)
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

  def show(conn, %{"id" => id, "organization_id" =>organization_id}) do
    IO.inspect("HERE")
    # confirm employee is assoc with this org
    employee = Staff.get_employee(id)
    employee_in_org? = Staff.check_employee_is_in_organization(employee, organization_id)
    IO.inspect(employee_in_org?)
    IO.inspect(!!employee_in_org?)
    if !!employee_in_org? do
      render(conn, "show.html", employee: employee)
    else
      conn
      |> put_flash(:error, "Invalid employee association.")
      |> redirect(to: Routes.organization_path(conn, :show, organization_id))
    end
  end

  def edit(conn,  %{"id" => id, "organization_id" =>organization_id}) do
    employee = Staff.get_employee(id)
    changeset = Staff.change_employee(employee)
    # add an action
    Map.put(conn.assigns, :action, Routes.organization_employee_path(conn, :create, organization_id, employee_id: id))
    conn
    |> render("edit.html", changeset: changeset, employee: employee, organization_id: organization_id)
  end

  # updates name, etc not email/PW
  def update(conn, %{"id" => id, "employee" => employee_params}) do
    # look up employee - could also use session
    employee = Staff.get_employee!(id)
# update automatically - framework uses changeset
    case Staff.update_employee(employee, employee_params) do
      {:ok, employee} ->
        conn
        |> put_flash(:info, "Employee updated successfully.")
        |> redirect(to: Routes.
        employee_path(conn, :show, employee.organization_id, employee.id))

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
      current_role === to_string(Enum.at(EmployeeManagerRolesEnum.get_roles, 0))  ->
        to_string(Enum.at(EmployeeManagerRolesEnum.get_roles, 0))
      # employee
      current_role === to_string(Enum.at(EmployeeManagerRolesEnum.get_roles, 1))  ->
        to_string(Enum.at(EmployeeManagerRolesEnum.get_roles, 1))
      # developer
      current_role === to_string(Enum.at(EmployeeManagerRolesEnum.get_roles, 2))  ->
        to_string(Enum.at(EmployeeManagerRolesEnum.get_roles, 2))


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
