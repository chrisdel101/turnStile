# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:

# ORGANZIATION1
TurnStile.Repo.transaction(fn ->
  org1_params = %{
    email: "org1@test.com",
    name: "Org1",
    phone: "777777777",
    slug: "org1"
  }

  {:ok, organization1} = TurnStile.Company.create_and_preload_organization(org1_params)
  # IO.inspect(organization1)

  # EMPLOYEE1
  emp1_params = %{
    email: "employee1@test.com",
    email_confirmation: "employee1@test.com",
    last_name: "Employee1",
    first_name: "Test1",
    password: "password",
    hashed_password: "password",
    current_organization_login_id: organization1.id,
    role_value_on_current_organization:
      to_string(RoleValuesMap.get_permission_role_value("owner")),
    role_on_current_organization: RoleValuesMap.get_permission_role("owner")
  }

  IO.inspect(emp1_params)
  {:ok, employee1} = TurnStile.Staff.register_and_preload_employee(emp1_params, organization1)
  IO.inspect(employee1)

  org_changeset = Ecto.Changeset.change(organization1)
  # put_assoc
  org_with_emps = Ecto.Changeset.put_assoc(org_changeset, :employees, [employee1])
  # IO.inspect(org_with_emps)

  {:ok, organization1} = TurnStile.Company.update_organization_changeset(org_with_emps)
  # IO.inspect(organization1)
  # IO.inspect(updated_org)

  # # EMPLOYEE2
  # emp2_params = %{
  #   email: "employee2@test.com",
  #   email_confirmation: "employee2@test.com",
  #   last_name: "Employee2",
  #   first_name: "Test2",
  #   password: "password",
  #   hashed_password: "password",
  #   current_organization_login_id: organization1.id,
  #   role_value_on_current_organization:
  #     to_string(RoleValuesMap.get_permission_role_value("admin")),
  #   role_on_current_organization: RoleValuesMap.get_permission_role("admin")
  # }

  #  {:ok, employee2} = TurnStile.Staff.register_and_preload_employee(emp2_params, organization1)
  # IO.inspect(employee2)

  # org_changeset2 = Ecto.Changeset.change(organization1)
  # # put_assoc
  # # IO.inspect(organization1)
  # org_with_emps = Ecto.Changeset.put_assoc(org_changeset2, :employees, [employee2 | organization1.employees])
  # # IO.inspect(org_with_emps)
  # {:ok, organization1} = TurnStile.Company.update_organization_changeset(org_with_emps)
  # # IO.inspect(organization1)

  # # ORGANZIATION2
  # org2_params = %{
  #   email: "org2@test.com",
  #   name: "Org2",
  #   phone: "777777777",
  #   slug: "org2"
  # }

  # {:ok, organization2} = TurnStile.Company.create_and_preload_organization(org2_params)
  # # IO.inspect(organization2)

  # # EMPLOYEE3
  # emp3_params = %{
  #   email: "employee3@test.com",
  #   email_confirmation: "employee3@test.com",
  #   last_name: "Employee3",
  #   first_name: "Test3",
  #   password: "password",
  #   hashed_password: "password",
  #   current_organization_login_id: organization2.id,
  #   role_value_on_current_organization:
  #     to_string(RoleValuesMap.get_permission_role_value("owner")),
  #   role_on_current_organization: RoleValuesMap.get_permission_role("owner")
  # }

  # {:ok, employee3} = TurnStile.Staff.register_and_preload_employee(emp3_params, organization2)
  # IO.inspect(employee3)

  # org_changeset = Ecto.Changeset.change(organization2)
  # # put_assoc
  # org_with_emps = Ecto.Changeset.put_assoc(org_changeset, :employees, [employee3])
  # # IO.inspect(org_with_emps)

  # {:ok, organization2} = TurnStile.Company.update_organization_changeset(org_with_emps)
  # # IO.inspect(organization2)
  # # IO.inspect(updated_org)

  # # EMPLOYEE4
  # emp2_params = %{
  #   email: "employee4@test.com",
  #   email_confirmation: "employee4@test.com",
  #   last_name: "Employee4",
  #   first_name: "Test4",
  #   password: "password",
  #   hashed_password: "password",
  #   current_organization_login_id: organization2.id,
  #   role_value_on_current_organization:
  #     to_string(RoleValuesMap.get_permission_role_value("editor")),
  #   role_on_current_organization: RoleValuesMap.get_permission_role("editor")
  # }

  #  {:ok, employee4} = TurnStile.Staff.register_and_preload_employee(emp2_params, organization2)
  # IO.inspect(employee4)

  # org_changeset2 = Ecto.Changeset.change(organization2)
  # # put_assoc
  # # IO.inspect(organization2)
  # org_with_emps = Ecto.Changeset.put_assoc(org_changeset2, :employees, [employee4 | organization2.employees])
  # # IO.inspect(org_with_emps)
  # {:ok, organization2} = TurnStile.Company.update_organization_changeset(org_with_emps)

  # # TurnStile.Repo.rollback({:rolling_back})
end)
