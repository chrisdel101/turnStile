defmodule TurnStile.EmployeeFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TurnStile.Staff` context.
  """

  def unique_employee_email, do: "employee#{System.unique_integer()}@example.com"
  def valid_employee_password, do: "hello world!"

  def valid_employee_client_type, do: ClientTypesEnum.get_client_type_value("employee")

  @spec fill_in_employee_attrs(map) :: %{
          :client_type => any,
          :current_organization_login_id => <<_::8>>,
          :first_name => <<_::40>>,
          :is_logged_in? => false,
          :last_name => <<_::40>>,
          :role_on_current_organization => any,
          :role_value_on_current_organization => binary,
          optional(any) => any
        }
  def fill_in_employee_attrs(attrs \\ %{}) do
    Map.merge(attrs, %{
      first_name: "Daffy",
      last_name: "Klown",
      client_type: valid_employee_client_type(),
      current_organization_login_id: "1",
      role_value_on_current_organization: to_string(EmployeeRolesMap.get_permission_role_value("ADMIN")),
      role_on_current_organization: EmployeeRolesMap.get_permission_role("ADMIN"),
      is_logged_in?: false
    })
  end
  def merge_employee_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_employee_email(),
      password: valid_employee_password()
    })
    |> Map.merge(fill_in_employee_attrs())
  end

  def employee_fixture(_attrs \\ %{}) do
    TurnStile.Staff.get_employee(1)
  end

  def employee_fixture1(attrs \\ %{}) do
    employee =
      attrs
      |> merge_employee_attributes()
      IO.inspect(employee)
    employee
  end

  def employee_fixture2(_attrs \\ %{}) do
    # TurnStile.Staff.get_employee(1)
     %TurnStile.Staff.Employee{last_name: "schmo", first_name: "joe", email: "joe1q@schmo.com", password: "password", hashed_password: "hashed_password"}
  end


  def extract_employee_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
