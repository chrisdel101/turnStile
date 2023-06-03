defmodule TurnStileWeb.EmployeeController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff

  # def new - removed: Use /employess/register instead

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

  def show(conn, %{"id" => id, "organization_id" => organization_id}) do
    show_validate_employee_id(conn, id)
    # confirm employee is assoc with this org
    employee = Staff.get_employee(id)
    employee_in_org? = Staff.check_employee_is_in_organization(employee, organization_id)

    if !!employee_in_org? do
      render(conn, "show.html", employee: employee)
    else
      conn
      |> put_flash(:error, "Invalid employee association.")
      |> redirect(to: Routes.organization_path(conn, :show, organization_id))
    end
  end

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
    # add an action
    Map.put(
      conn.assigns,
      :action,
      Routes.organization_employee_path(conn, :create, organization_id, employee_id: id)
    )

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
  - has_sufficient_update_permissions??

  """
  def update(conn, %{"id" => id, "employee" => employee_params}) do
    IO.inspect("HERE")
    IO.inspect(employee_params)
    # look up employee that is being edited
    employee_to_update = Staff.get_employee(id)

    if !TurnStileWeb.EmployeeAuth.has_sufficient_update_permissions?(conn, employee_to_update) do
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
                Map.get(get_session(conn), "current_organization_id_str"),
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

  def delete(conn, %{"id" => id}) do
    employee = Staff.get_employee(id)
    {:ok, _employee} = Staff.delete_employee(employee)

    conn
    |> put_flash(:info, "Employee deleted successfully.")
    |> redirect(to: Routes.employee_path(conn, :index))
  end
end
