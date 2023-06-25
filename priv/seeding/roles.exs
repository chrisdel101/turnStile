alias Ecto.Multi

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

  role =
    TurnStile.Roles.build_role(
      %{
        name: ex2.role_on_current_organization,
        value:
          to_string(EmployeeRolesMap.get_permission_role_value(ex2.role_on_current_organization))
      }
    )
  # role =
  #   TurnStile.Roles.create_role(
  #     %TurnStile.Roles.Role{},
  #     %{
  #       name: ex2.role_on_current_organization,
  #       value:
  #         to_string(EmployeeRolesMap.get_permission_role_value(ex2.role_on_current_organization))
  #     }
  #   )

  {:ok, employee1} = TurnStile.Staff.insert_register_employee(ex2, organization1)
  role = Ecto.build_assoc(employee1, :roles, role)
  IO.inspect(role)

  # TurnStile.Repo.insert(role)

  # updated_emp = TurnStile.Staff.change_role_assoc(employee1, role)
  # IO.inspect(updated_emp.data, label: "HERE")

  # {:ok, updated_org2} = TurnStile.Company.handle_add_assoc_role(organization1, role)
  {:ok, updated_org} = TurnStile.Company.handle_add_assoc_employee(organization1, employee1)
  role = Ecto.build_assoc(employee1, :roles, role)
  role = Ecto.build_assoc(updated_org, :roles, role)
  IO.inspect(role)
  TurnStile.Repo.insert(role)
  # IO.inspect(updated_org2)
  # IO.inspect(updated_emp)
  # update_org =
  #   updated_org
  #   |> TurnStile.Company.change_organization(org1_params)
  #   |> Ecto.Changeset.put_assoc(:roles, [role])
  TurnStile.Company.update_organization(updated_org)
  # TurnStile.Repo.rollback({:rolling_back})
end)
