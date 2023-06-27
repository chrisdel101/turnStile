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

  TurnStile.Roles.insert_role(employee1.id, org_w_emps.id, role)
  # EMPLOYEE2 - admin
  emp2_params = %{
    email: "sam2@jones.com",
    email_confirmation: "sam2@jones.com",
    last_name: "Jones2",
    first_name: "Sam",
    password: "password"
    }

  {:ok, employee2} =
    TurnStile.Staff.insert_register_employee(emp2_params, organization: organization1)

  {:ok, org_w_emps} = TurnStile.Company.update_employee_assoc(organization1, employee2)

  role =
    TurnStile.Roles.build_role(%{
      name: EmployeeRolesMap.get_permission_role("ADMIN"),
      value: to_string(EmployeeRolesMap.get_permission_role_value("ADMIN"))
    })

  # add has_many role assocations
  role = TurnStile.Roles.assocaiate_role_with_employee(role, employee2)
  role = TurnStile.Roles.assocaiate_role_with_organization(role, org_w_emps)
  TurnStile.Roles.insert_role(employee2.id, org_w_emps.id, role)

  # EMPLOYEE2 - admin
  emp7_params = %{
    email: "sam7@jones.com",
    email_confirmation: "sam7@jones.com",
    last_name: "Jones7",
    first_name: "Sam",
    password: "password",
  }

  {:ok, employee7} =
    TurnStile.Staff.insert_register_employee(emp7_params, organization: organization1)

  {:ok, org_w_emps} = TurnStile.Company.update_employee_assoc(organization1, employee7)
  role =
    TurnStile.Roles.build_role(%{
      name: EmployeeRolesMap.get_permission_role("ADMIN"),
      value: to_string(EmployeeRolesMap.get_permission_role_value("ADMIN"))
    })

  # add has_many role assocations
  role = TurnStile.Roles.assocaiate_role_with_employee(role, employee7)
  role = TurnStile.Roles.assocaiate_role_with_organization(role, org_w_emps)
  TurnStile.Roles.insert_role(employee7.id, org_w_emps.id, role)

  # EMPLOYEE3 - EDITOR
  emp3_params = %{
    email: "sam3@jones.com",
    email_confirmation: "sam3@jones.com",
    last_name: "Jones3",
    first_name: "Sam",
    password: "password",
  }

  {:ok, employee3} =
    TurnStile.Staff.insert_register_employee(emp3_params, organization: organization1)

  {:ok, org_w_emps} = TurnStile.Company.update_employee_assoc(organization1, employee3)

  role =
    TurnStile.Roles.build_role(%{
      name: EmployeeRolesMap.get_permission_role("EDITOR"),
      value: to_string(EmployeeRolesMap.get_permission_role_value("EDITOR"))
    })

  # add has_many role assocations
  role = TurnStile.Roles.assocaiate_role_with_employee(role, employee3)
  role = TurnStile.Roles.assocaiate_role_with_organization(role, org_w_emps)
  TurnStile.Roles.insert_role(employee3.id, org_w_emps.id, role)

  # EMPLOYEE4 - CONTRIBUTOR
  emp4_params = %{
    email: "sam4@jones.com",
    email_confirmation: "sam4@jones.com",
    last_name: "Jones4",
    first_name: "Sam",
    password: "password"
  }

  {:ok, employee4} =
    TurnStile.Staff.insert_register_employee(emp4_params, organization: organization1)

  {:ok, org_w_emps} = TurnStile.Company.update_employee_assoc(organization1, employee4)

  role =
    TurnStile.Roles.build_role(%{
      name: EmployeeRolesMap.get_permission_role("CONTRIBUTOR"),
      value: to_string(EmployeeRolesMap.get_permission_role_value("CONTRIBUTOR"))
    })

  # add has_many role assocations
  role = TurnStile.Roles.assocaiate_role_with_employee(role, employee4)
  role = TurnStile.Roles.assocaiate_role_with_organization(role, org_w_emps)
  TurnStile.Roles.insert_role(employee4.id, org_w_emps.id, role)
  # EMPLOYEE5 - CONTRIBUTOR
  emp5_params = %{
    email: "sam5@jones.com",
    email_confirmation: "sam5@jones.com",
    last_name: "Jones5",
    first_name: "Sam",
    password: "password"
  }

  {:ok, employee5} =
    TurnStile.Staff.insert_register_employee(emp5_params, organization: organization1)

  {:ok, org_w_emps} = TurnStile.Company.update_employee_assoc(organization1, employee5)
  role =
    TurnStile.Roles.build_role(%{
      name: EmployeeRolesMap.get_permission_role("CONTRIBUTOR"),
      value: to_string(EmployeeRolesMap.get_permission_role_value("CONTRIBUTOR"))
    })

  # add has_many role assocations
  role = TurnStile.Roles.assocaiate_role_with_employee(role, employee5)
  role = TurnStile.Roles.assocaiate_role_with_organization(role, org_w_emps)
  TurnStile.Roles.insert_role(employee5.id, org_w_emps.id, role)
  # EMPLOYEE6 - VIEWER
  emp6_params = %{
    email: "sam6@jones.com",
    email_confirmation: "sam6@jones.com",
    last_name: "Jones6",
    first_name: "Sam",
    password: "password"
  }

  {:ok, employee6} =
    TurnStile.Staff.insert_register_employee(emp6_params, organization: organization1)

  {:ok, org_w_emps} = TurnStile.Company.update_employee_assoc(organization1, employee6)
  role =
    TurnStile.Roles.build_role(%{
      name: EmployeeRolesMap.get_permission_role("VIEWER"),
      value: to_string(EmployeeRolesMap.get_permission_role_value("VIEWER"))
    })

  # add has_many role assocations
  role = TurnStile.Roles.assocaiate_role_with_employee(role, employee6)
  role = TurnStile.Roles.assocaiate_role_with_organization(role, org_w_emps)
  TurnStile.Roles.insert_role(employee6.id, org_w_emps.id, role)

  # USERS W ORG1
  user1 = %{
    first_name: "Joe",
    last_name: "Schmoe",
    email: "joe1@schmoe.com",
    phone: "777777777",
    health_card_num: 1234
  }

  # user w/ emp and org assocs
  {:ok, user1} = TurnStile.Patients.create_user_w_assocs(employee1, user1, organization1)

  user2 = %{
    first_name: "Joe2",
    last_name: "Schmoe",
    email: "joe2@schmoe.com",
    phone: "777777777",
    health_card_num: 5678
  }

  # user w/ emp and org assocs
  {:ok, user2} = TurnStile.Patients.create_user_w_assocs(employee1, user2, organization1)

  user3 = %{
    first_name: "Joe3",
    last_name: "Schmoe",
    email: "joe3@schmoe.com",
    phone: "777777777",
    health_card_num: 9010
  }

  # user w/ emp and org assocs
  {:ok, user3} = TurnStile.Patients.create_user_w_assocs(employee1, user3, organization1)

  user4 = %{
    first_name: "Joe4",
    last_name: "Schmoe",
    email: "joe4@schmoe.com",
    phone: "777777777",
    health_card_num: 1112
  }

  # user w/ emp and org assocs
  {:ok, user4} = TurnStile.Patients.create_user_w_assocs(employee1, user4, organization1)

  {:ok, user1} = TurnStile.Repo.insert(user1)
  {:ok, user2} = TurnStile.Repo.insert(user2)
  {:ok, user3} = TurnStile.Repo.insert(user3)
  {:ok, user4} = TurnStile.Repo.insert(user4)

  # ALERTS
  a1 = %{
    alert_category: "initial",
    alert_format: "sms",
    body: "some body1",
    title: "alert1"
  }

  {:ok, alert} = TurnStile.Alerts.create_alert_w_assoc(employee1, user1, a1)
  TurnStile.Alerts.insert_alert(alert)

  a4 = %{
    alert_category: "confirmation",
    alert_format: "sms",
    body: "some body4",
    title: "alert4"
  }

  {:ok, alert} = TurnStile.Alerts.create_alert_w_assoc(employee1, user1, a4)
  TurnStile.Alerts.insert_alert(alert)

  a2 = %{
    alert_category: "initial",
    alert_format: "sms",
    body: "some body2",
    title: "alert2"
  }

  {:ok, alert} = TurnStile.Alerts.create_alert_w_assoc(employee1, user1, a2)
  TurnStile.Alerts.insert_alert(alert)

  a3 = %{
    alert_category: "initial",
    alert_format: "sms",
    body: "some body3",
    title: "alert3"
  }

  {:ok, alert} = TurnStile.Alerts.create_alert_w_assoc(employee1, user1, a3)
  TurnStile.Alerts.insert_alert(alert)

    # # ORGANZIATION2
    org2_params = %{
      email: "org2@test.com",
      name: "Org2",
      phone: "777777777",
      slug: "org2"
    }

  {:ok, organization2} = TurnStile.Company.insert_and_preload_organization(org2_params)

  # # IO.inspect(organization2)

  # # EMPLOYEE3
  emp1_02_params = %{
    email: "employee3@test.com",
    email_confirmation: "employee3@test.com",
    last_name: "Employee3",
    first_name: "Test3",
    password: "password",
  }

  # {:ok, employee3} = TurnStile.Staff.insert_register_employee(emp3_params, organization2)
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
  #   current_organization_login_id: organization2.id,")),

  # }

  #  {:ok, employee4} = TurnStile.Staff.insert_register_employee(emp2_params, organization2)
  # IO.inspect(employee4)

  # org_changeset2 = Ecto.Changeset.change(organization2)
  # # put_assoc
  # # IO.inspect(organization2)
  # org_with_emps = Ecto.Changeset.put_assoc(org_changeset2, :employees, [employee4 | organization2.employees])
  # # IO.inspect(org_with_emps)
  # {:ok, organization2} = TurnStile.Company.update_organization_changeset(org_with_emps)

  # TurnStile.Repo.rollback({:rolling_back})
end)
