TurnStile.Repo.transaction(fn ->
  org1_params = %{
    email: "org1@test.com",
    name: "Org1",
    phone: "777777777",
    slug: "org1"
  }

  # insert org w 3 preloads
  {:ok, organization1} = TurnStile.Company.insert_and_preload_organization(org1_params)

  ex2 = %{
    email: "joe22@schmo.com",
    email_confirmation: "joe22@schmo.com",
    first_name: "Joe ",
    last_name: "Schmo",
    password: "password",
    current_organization_login_id: nil,
    password_confirmation: "password",
    role_value_on_current_organization: nil,
    role_on_current_organization: EmployeeRolesMap.get_permission_role("OWNER"),
    timezone: "America/New_York"
  }
  {:ok, employee1} = TurnStile.Staff.insert_register_employee(ex2, [organization: organization1])

  {:ok, updated_org} = TurnStile.Company.handle_add_assoc_employee(organization1, employee1)
  role =
    TurnStile.Roles.build_role(%{
      name: EmployeeRolesMap.get_permission_role("OWNER"),
      value: to_string(EmployeeRolesMap.get_permission_role_value("OWNER"))
      })
    # add has_many role assocations
    role = TurnStile.Roles.assocaiate_role_with_employee(role, employee1)
    role = TurnStile.Roles.assocaiate_role_with_employee(role, organization1)

  TurnStile.Repo.insert(role)

  TurnStile.Company.update_organization(updated_org)
  TurnStile.Repo.rollback({:rolling_back})
end)
