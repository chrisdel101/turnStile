# Code.load_file
# TurnStile.Repo.transaction(fn ->
org1_params = %{
  email: "org1@test.com",
  name: "Org1",
  phone: "777777777",
  slug: "org1"
}

{:ok, organization1} = TurnStile.Company.insert_and_preload_organization(org1_params)
# IO.inspect(organization1)

# EMPLOYEE1 - OWNER
emp1_params = %{
  email: "sam1@jones.com",
  email_confirmation: "sam1@jones.com",
  last_name: "Jones1",
  first_name: "Sam",
  password: "password",
}

{:ok, employee1} =
  TurnStile.Staff.insert_register_employee(emp1_params, organization: organization1)

#  IO.inspect(employee1)
{:ok, org_w_emps} = TurnStile.Company.update_employee_assoc(organization1, employee1)

role =
  TurnStile.Roles.build_role(%{
    name: EmployeeRolesMap.get_permission_role("OWNER"),
    value: to_string(EmployeeRolesMap.get_permission_role_value("OWNER"))
  })

# add has_many role assocations
role = TurnStile.Roles.assocaiate_role_with_employee(role, employee1)
role = TurnStile.Roles.assocaiate_role_with_organization(role, org_w_emps)

# USERS W ORG1
user1 = %{
  first_name: "Joe",
  last_name: "Schmoe",
  email: "joe1@schmoe.com",
  phone: "777777777",
  health_card_num: 1234
}
{:ok, role1} = TurnStile.Roles.insert_role(employee1.id, org_w_emps.id, role)

{:ok, user1} = TurnStile.Patients.create_user_w_assocs(employee1, user1, role1, organization1)
{:ok, user1} = TurnStile.Patients.insert_user_struct(user1)
# IO.inspect(role1, label: "AAAAAA")

all = %{

  organization: organization1,
  employee: employee1,
  role: role1,
  user: user1
}

# IO.inspect(all, label: "AAAAAA")
  # TurnStile .Repo.rollback({:rolling_back})
# end)


# {_, all} = List.last(elem(Code.eval_file("./loader.exs"),1))
