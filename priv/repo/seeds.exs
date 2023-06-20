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

  # EMPLOYEE1 - OWNER
  emp1_params = %{
    email: "sam1@jones.com",
    email_confirmation: "sam1@jones.com",
    last_name: "Jones1",
    first_name: "Sam",
    password: "password",
    hashed_password: "password",
    current_organization_login_id: organization1.id,
    role_value_on_current_organization:
      to_string(EmployeeRolesMap.get_permission_role_value("owner")),
    role_on_current_organization: EmployeeRolesMap.get_permission_role("OWNER"),
    timezone: "America/New_York"
  }
  {:ok, employee1} = TurnStile.Staff.register_and_preload_employee(emp1_params, organization1)
  #  IO.inspect(employee1)
   org_changeset = Ecto.Changeset.change(organization1)
  #  IO.inspect(org_changeset)
  # put_assoc
  org_with_emps = Ecto.Changeset.put_assoc(org_changeset, :employees, [employee1])
  {:ok, organization1} = TurnStile.Company.update_organization_changeset(org_with_emps)
  # EMPLOYEE2 - admin
  emp2_params = %{
    email: "sam2@jones.com",
    email_confirmation: "sam2@jones.com",
    last_name: "Jones2",
    first_name: "Sam",
    password: "password",
    hashed_password: "password",
    current_organization_login_id: organization1.id,
    role_value_on_current_organization:
      to_string(EmployeeRolesMap.get_permission_role_value("admin")),
    role_on_current_organization: EmployeeRolesMap.get_permission_role("ADMIN")
  }
   {:ok, employee2} = TurnStile.Staff.register_and_preload_employee(emp2_params, organization1)
  org_changeset2 = Ecto.Changeset.change(organization1)
  # put_assoc
  org_with_emps = Ecto.Changeset.put_assoc(org_changeset2, :employees, [employee2 | organization1.employees])
  {:ok, organization1} = TurnStile.Company.update_organization_changeset(org_with_emps)
  # EMPLOYEE2 - admin
  emp7_params = %{
    email: "sam7@jones.com",
    email_confirmation: "sam7@jones.com",
    last_name: "Jones7",
    first_name: "Sam",
    password: "password",
    hashed_password: "password",
    current_organization_login_id: organization1.id,
    role_value_on_current_organization:
      to_string(EmployeeRolesMap.get_permission_role_value("admin")),
    role_on_current_organization: EmployeeRolesMap.get_permission_role("ADMIN")
  }
   {:ok, employee7} = TurnStile.Staff.register_and_preload_employee(emp7_params, organization1)
  org_changeset2 = Ecto.Changeset.change(organization1)
  # put_assoc
  org_with_emps = Ecto.Changeset.put_assoc(org_changeset2, :employees, [employee7 | organization1.employees])
  {:ok, organization1} = TurnStile.Company.update_organization_changeset(org_with_emps)
    # EMPLOYEE3 - EDITOR
  emp3_params = %{
    email: "sam3@jones.com",
    email_confirmation: "sam3@jones.com",
    last_name: "Jones3",
    first_name: "Sam",
    password: "password",
    hashed_password: "password",
    current_organization_login_id: organization1.id,
    role_value_on_current_organization:
      to_string(EmployeeRolesMap.get_permission_role_value("editor")),
    role_on_current_organization: EmployeeRolesMap.get_permission_role("EDITOR")
  }
   {:ok, employee3} = TurnStile.Staff.register_and_preload_employee(emp3_params, organization1)
  org_changeset2 = Ecto.Changeset.change(organization1)
  # put_assoc
  org_with_emps = Ecto.Changeset.put_assoc(org_changeset2, :employees, [employee3 | organization1.employees])
  {:ok, organization1} = TurnStile.Company.update_organization_changeset(org_with_emps)
    # EMPLOYEE4 - CONTRIBUTOR
  emp4_params = %{
    email: "sam4@jones.com",
    email_confirmation: "sam4@jones.com",
    last_name: "Jones4",
    first_name: "Sam",
    password: "password",
    hashed_password: "password",
    current_organization_login_id: organization1.id,
    role_value_on_current_organization:
      to_string(EmployeeRolesMap.get_permission_role_value("contributor")),
    role_on_current_organization: EmployeeRolesMap.get_permission_role("CONTRIBUTOR")
  }
   {:ok, employee4} = TurnStile.Staff.register_and_preload_employee(emp4_params, organization1)
  org_changeset2 = Ecto.Changeset.change(organization1)
  # put_assoc
  org_with_emps = Ecto.Changeset.put_assoc(org_changeset2, :employees, [employee4 | organization1.employees])
  {:ok, organization1} = TurnStile.Company.update_organization_changeset(org_with_emps)
    # EMPLOYEE5 - CONTRIBUTOR
  emp5_params = %{
    email: "sam5@jones.com",
    email_confirmation: "sam5@jones.com",
    last_name: "Jones5",
    first_name: "Sam",
    password: "password",
    hashed_password: "password",
    current_organization_login_id: organization1.id,
    role_value_on_current_organization:
      to_string(EmployeeRolesMap.get_permission_role_value("contributor")),
    role_on_current_organization: EmployeeRolesMap.get_permission_role("CONTRIBUTOR")
  }
   {:ok, employee5} = TurnStile.Staff.register_and_preload_employee(emp5_params, organization1)
  org_changeset2 = Ecto.Changeset.change(organization1)
  # put_assoc
  org_with_emps = Ecto.Changeset.put_assoc(org_changeset2, :employees, [employee5 | organization1.employees])
  {:ok, organization1} = TurnStile.Company.update_organization_changeset(org_with_emps)
    # EMPLOYEE6 - VIEWER
  emp6_params = %{
    email: "sam6@jones.com",
    email_confirmation: "sam6@jones.com",
    last_name: "Jones6",
    first_name: "Sam",
    password: "password",
    hashed_password: "password",
    current_organization_login_id: organization1.id,
    role_value_on_current_organization:
      to_string(EmployeeRolesMap.get_permission_role_value("viewer")),
    role_on_current_organization: EmployeeRolesMap.get_permission_role("VIEWER")
  }
   {:ok, employee6} = TurnStile.Staff.register_and_preload_employee(emp6_params, organization1)
  org_changeset2 = Ecto.Changeset.change(organization1)
  # put_assoc
  org_with_emps = Ecto.Changeset.put_assoc(org_changeset2, :employees, [employee6 | organization1.employees])
  {:ok, organization1} = TurnStile.Company.update_organization_changeset(org_with_emps)

  # USERS
  user1 = %{
    first_name: "Joe",
    last_name: "Schmoe",
    email: "joe1@schmoe.com",
    phone: "777777777",
    health_card_num: 1234
  }
  TurnStile.Patients.handle_new_user_association_create(employee1, user1)
  user2 = %{
    first_name: "Joe2",
    last_name: "Schmoe",
    email: "joe2@schmoe.com",
    phone: "777777777",
    health_card_num: 5678
  }
  TurnStile.Patients.handle_new_user_association_create(employee1, user2)
  user3 = %{
    first_name: "Joe3",
    last_name: "Schmoe",
    email: "joe3@schmoe.com",
    phone: "777777777",
    health_card_num: 9010
  }
  TurnStile.Patients.handle_new_user_association_create(employee1, user3)
  user4 = %{
    first_name: "Joe4",
    last_name: "Schmoe",
    email: "joe4@schmoe.com",
    phone: "777777777",
    health_card_num: 1112
  }
  TurnStile.Patients.handle_new_user_association_create(employee1, user4)

  # ALERTS
  a1 = %{
    alert_category: "initial",
    alert_format: "sms",
    body: "some body1",
    title: "alert1"
  }
  TurnStile.Alerts.insert_alert_w_assoc(1, 1, a1)
  a4 = %{
    alert_category: "confirmation",
    alert_format: "sms",
    body: "some body4",
    title: "alert4"
  }
  TurnStile.Alerts.insert_alert_w_assoc(1, 1, a4)
  a2 = %{
    alert_category: "initial",
    alert_format: "sms",
    body: "some body2",
    title: "alert2"
  }
  TurnStile.Alerts.insert_alert_w_assoc(1, 2, a2)
  a3 = %{
    alert_category: "initial",
    alert_format: "sms",
    body: "some body3",
    title: "alert3"
  }
  TurnStile.Alerts.insert_alert_w_assoc(1, 3, a3)


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
  #     to_string(EmployeeRolesMap.get_permission_role_value("OWNER")),
  #   role_on_current_organization: EmployeeRolesMap.get_permission_role("OWNER")
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
  #     to_string(EmployeeRolesMap.get_permission_role_value("EDITOR")),
  #   role_on_current_organization: EmployeeRolesMap.get_permission_role("EDITOR")
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
