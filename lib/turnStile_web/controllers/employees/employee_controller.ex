defmodule TurnStileWeb.EmployeeController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff

  # note: new func does is not implemented. Use register instead

  # lists all employees in an organization
  # all-acccess
  def index(conn, _params) do
    organization_id = conn.params["organization_id"]

    if !organization_id do
      conn
      |> put_flash(:error, "An Organization ID error ocurred. Make sure it exists.")
      |> redirect(to: Routes.organization_path(conn, :index))
    end

    # get all employees in the organization by id
    employee_ids =
      Staff.list_employee_ids_by_organization(TurnStile.Utils.convert_to_int(organization_id))

    # lookup all those ids
    employees = Staff.list_employees_by_ids(employee_ids)
    render(conn, "index.html", employees: employees, organization_id: organization_id, page_title: "Listing Employees")
  end

  def show(conn, %{"id" => id, "organization_id" => organization_id}) do
    show_validate_employee_id(conn, id)
    # get employee to look up
    employee = Staff.get_employee(id)
    # confirm employee is assoc with this org
    employee_in_org? = Staff.check_employee_is_in_organization(employee, organization_id)

    if !!employee_in_org? do
      render(conn, "show.html", employee: employee)
    else
      conn
      |> put_flash(:error, "Invalid employee association. That employee is not in this organization or another error occurred.")
      |> redirect(to: Routes.organization_path(conn, :show, organization_id))
    end
  end
  # handle invalid url params in employee_id slot
  # TODO: make better error handling
  defp show_validate_employee_id(conn, id) do
    case TurnStile.Utils.is_digit(id) do
      true ->
        conn
      false ->
        conn
        |> put_status(404)
        |> text("Invalid employee id")
        |> halt()
    end
  end

  def edit(conn, %{"id" => id, "organization_id" => organization_id}) do
    employee = Staff.get_employee(id)
    changeset = Staff.change_employee(employee)

    conn
    |> render("edit.html",
      changeset: changeset,
      employee: employee,
      organization_id: organization_id
    )
  end

  @doc """
  Updates organization-only related fields
  - require_authenticated_employee
  - require_edit_access_employee
  """
  def update(conn, %{"id" => id, "employee" => employee_params}) do
    current_employee = conn.assigns[:current_employee]
    # look up employee that is being edited
    employee_to_update = Staff.get_employee(id)
    # IO.inspect(employee_to_update)
    # check current_employee can edit THIS employee
    if TurnStileWeb.EmployeeAuth.has_employee_edit_permissions?(conn, employee_to_update) do
      conn
      |> put_flash(:error, "Error in employee edit. Insufficient permissions.")
      |> redirect(to: Routes.organization_path(conn, :index))
    else
      case Staff.update_employee(employee_to_update, employee_params) do
        {:ok, employee_to_update} ->
          conn
          |> put_flash(:info, "Employee updated successfully.")
          |> redirect(
            to:
              Routes.organization_employee_path(
                conn,
                :show,
                current_employee.current_organization_login_id,
                employee_to_update.id
              )
          )

        {:error, %Ecto.Changeset{} = changeset} ->
          IO.inspect("ERROR")
          IO.inspect(changeset)
          render(conn, "edit.html", employee: employee_to_update, changeset: changeset)
      end
    end
  end
  @doc """
  Mock Deletes an employee:
  - there is no true delete employee; only Mock delete
  - To keep all FK relationships intact
  - delelete only deactives employee and removes from system use
  - only when organization is deleted is employee truly deleted
  """
  def delete(conn, %{"id" => id}) do

    employee_to_delete = Staff.get_employee(id)
    current_employee = conn.assigns[:current_employee]


    if !TurnStileWeb.EmployeeAuth.has_employee_delete_permissions?(conn, employee_to_delete) do
      conn
      |> put_flash(:error, "Error in employee delete. Insufficient permissions.")
      |> redirect(to: Routes.organization_path(conn, :index))
    else
      case Staff.deactivate_employee(employee_to_delete) do

        {:ok, employee_to_delete} ->
          conn
          |> put_flash(:info, "Employee deleted successfully.")
          |> redirect(to: Routes.organization_employee_path(conn, :index,  current_employee
          |> Map.get(:current_organization_login_id, nil)))
          # re-render the same page
        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_flash(:info, "An error occured. See dev logs or contant support.")
          IO.inspect(changeset)
          redirect(conn, to:  Routes.organization_employee_path(conn, :index,  current_employee || conn.request_path))
      end

    end
  end
end
