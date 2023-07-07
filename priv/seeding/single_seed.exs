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


  {:ok, role1} = TurnStile.Roles.insert_role(employee1.id, org_w_emps.id, role)

  # USERS W ORG1
  user1 = %{
    first_name: "Joe",
    last_name: "Schmoe",
    email: "joe1@schmoe.com",
    phone: "777777777",
    health_card_num: 1234
  }

  # user w/ emp and org assocs
  {:ok, user1} = TurnStile.Patients.create_user_w_assocs(employee1, user1, role1, organization1)


  {:ok, user1} = TurnStile.Patients.insert_user(user1)

  # ALERTS
  a1 = %{
    alert_category: "initial",
    alert_format: "sms",
    body: "some body1",
    title: "alert1",
    to: user1.phone,
    from: System.get_env("SYSTEM_ALERT_FROM_SMS")
  }
  {:ok, alert} = TurnStile.Alerts.create_alert_w_build_assoc(employee1, user1, a1, role1, organization1)
  # IO.inspect(alert)
  TurnStile.Alerts.insert_alert(alert)

  # a4 = %{
  #   alert_category: "confirmation",
  #   alert_format: "sms",
  #   body: "some body4",
  #   title: "alert4",
  #   to: user1.phone,
  #   from: System.get_env("SYSTEM_ALERT_FROM_SMS")
  # }

  # {:ok, alert} = TurnStile.Alerts.create_alert_w_build_assoc(employee1, user1, a4, role1, organization1)
  # TurnStile.Alerts.insert_alert(alert)

  # a2 = %{
  #   alert_category: "initial",
  #   alert_format: "sms",
  #   body: "some body2",
  #   title: "alert2",
  #   to: user1.phone,
  #   from: System.get_env("SYSTEM_ALERT_FROM_SMS")
  # }

  # {:ok, alert} = TurnStile.Alerts.create_alert_w_build_assoc(employee1, user1, a2, role1, organization1)
  # TurnStile.Alerts.insert_alert(alert)

  # a3 = %{
  #   alert_category: "initial",
  #   alert_format: "sms",
  #   body: "some body3",
  #   title: "alert3",
  #   to: user1.phone,
  #   from: System.get_env("SYSTEM_ALERT_FROM_SMS")

  # }

  # {:ok, alert} = TurnStile.Alerts.create_alert_w_build_assoc(employee1, user1, a3, role1, organization1)
  # TurnStile.Alerts.insert_alert(alert)

  # #   ############# ORGANZIATION2 ############
  #   org2_params = %{
  #     email: "org2@test.com",
  #     name: "Org2",
  #     phone: "777777777",
  #     slug: "org2"
  #   }

  # {:ok, organization2} = TurnStile.Company.insert_and_preload_organization(org2_params)

  # # # IO.inspect(organization2)

  # emp9_params = %{
  #   email: "sam9@jones.com",
  #   email_confirmation: "sam9@jones.com",
  #   last_name: "Jones9",
  #   first_name: "Sam",
  #   password: "password",
  # }

  # {:ok, employee9} =
  #   TurnStile.Staff.insert_register_employee(emp9_params, organization: organization2)

  # {:ok, org_w_emps} = TurnStile.Company.update_employee_assoc(organization2, employee9)

  # role =
  #   TurnStile.Roles.build_role(%{
  #     name: EmployeeRolesMap.get_permission_role("OWNER"),
  #     value: to_string(EmployeeRolesMap.get_permission_role_value("OWNER"))
  #   })

  # # add has_many role assocations
  # role = TurnStile.Roles.assocaiate_role_with_employee(role, employee9)
  # role = TurnStile.Roles.assocaiate_role_with_organization(role, org_w_emps)

  # {:ok, role9} =TurnStile.Roles.insert_role(employee9.id, org_w_emps.id, role)

  # emp10_params = %{
  #   email: "sam10@jones.com",
  #   email_confirmation: "sam10@jones.com",
  #   last_name: "Jones10",
  #   first_name: "Sam",
  #   password: "password",
  # }

  # {:ok, employee10} =
  #   TurnStile.Staff.insert_register_employee(emp10_params, organization: organization2)

  # {:ok, org_w_emps} = TurnStile.Company.update_employee_assoc(organization2, employee10)

  # role =
  #   TurnStile.Roles.build_role(%{
  #     name: EmployeeRolesMap.get_permission_role("CONTRIBUTOR"),
  #     value: to_string(EmployeeRolesMap.get_permission_role_value("CONTRIBUTOR"))
  #   })

  # # add has_many role assocations
  # role = TurnStile.Roles.assocaiate_role_with_employee(role, employee10)
  # role = TurnStile.Roles.assocaiate_role_with_organization(role, org_w_emps)

  # {:ok, role10} = TurnStile.Roles.insert_role(employee10.id, org_w_emps.id, role)

  # # ADD EXISTING EMPLOYEE TO ORG2
  # {:ok, org_w_emps} = TurnStile.Company.update_employee_assoc(organization2, employee1)

  # role =
  #   TurnStile.Roles.build_role(%{
  #     name: EmployeeRolesMap.get_permission_role("CONTRIBUTOR"),
  #     value: to_string(EmployeeRolesMap.get_permission_role_value("CONTRIBUTOR"))
  #   })

  # # add has_many role assocations
  # role = TurnStile.Roles.assocaiate_role_with_employee(role, employee1)
  # role = TurnStile.Roles.assocaiate_role_with_organization(role, org_w_emps)

  # {:ok, rolexy} = TurnStile.Roles.insert_role(employee1.id, org_w_emps.id, role)


  # emp11_params = %{
  #   email: "sam11@jones.com",
  #   email_confirmation: "sam11@jones.com",
  #   last_name: "Jones11",
  #   first_name: "Sam",
  #   password: "password",
  # }

  # {:ok, employee11} =
  #   TurnStile.Staff.insert_register_employee(emp11_params, organization: organization2)

  # {:ok, org_w_emps} = TurnStile.Company.update_employee_assoc(organization2, employee11)

  # role =
  #   TurnStile.Roles.build_role(%{
  #     name: EmployeeRolesMap.get_permission_role("VIEWER"),
  #     value: to_string(EmployeeRolesMap.get_permission_role_value("VIEWER"))
  #   })

  # # add has_many role assocations
  # role = TurnStile.Roles.assocaiate_role_with_employee(role, employee11)
  # role = TurnStile.Roles.assocaiate_role_with_organization(role, org_w_emps)


  # {:ok, role11} = TurnStile.Roles.insert_role(employee11.id, org_w_emps.id, role)



  # # USERS W ORG1
  # user5 = %{
  #   first_name: "Joe5",
  #   last_name: "Schmoe",
  #   email: "joe5@schmoe.com",
  #   phone: "777777777",
  #   health_card_num: 3141
  # }

  # # user w/ emp and org assocs
  # {:ok, user5} = TurnStile.Patients.create_user_w_assocs(employee10, user5, role10, organization2)

  # user6 = %{
  #   first_name: "Joe6",
  #   last_name: "Schmoe",
  #   email: "joe6@schmoe.com",
  #   phone: "777777777",
  #   health_card_num: 5161
  # }

  # # user w/ emp and org assocs
  # {:ok, user6} = TurnStile.Patients.create_user_w_assocs(employee1, user6, rolexy, organization2)

  # user7 = %{
  #   first_name: "Joe7",
  #   last_name: "Schmoe",
  #   email: "joe8@schmoe.com",
  #   phone: "777777777",
  #   health_card_num: 7181
  # }

  # # user w/ emp and org assocs
  # {:ok, user7} = TurnStile.Patients.create_user_w_assocs(employee9, user7, role9, organization2)

  # user8 = %{
  #   first_name: "Joe9",
  #   last_name: "Schmoe",
  #   email: "joe9@schmoe.com",
  #   phone: "777777777",
  #   health_card_num: 8191
  # }
  # {:ok, user8} = TurnStile.Patients.create_user_w_assocs(employee9, user8, role9, organization2)

  # {:ok, user5} = TurnStile.Patients.insert_user(user5)
  # {:ok, user6} = TurnStile.Patients.insert_user(user6)
  # {:ok, user7} = TurnStile.Patients.insert_user(user7)
  # {:ok, user8} = TurnStile.Patients.insert_user(user8)

  # # ALERTS
  # a5 = %{
  #   alert_category: "initial",
  #   alert_format: "sms",
  #   body: "some body1",
  #   title: "alert1",
  #   to: user5.phone,
  #   from: System.get_env("SYSTEM_ALERT_FROM_SMS")
  # }

  # {:ok, alert} = TurnStile.Alerts.create_alert_w_build_assoc(employee9, user5, a5, role9, organization2)
  # TurnStile.Alerts.insert_alert(alert)

  # a6 = %{
  #   alert_category: "confirmation",
  #   alert_format: "sms",
  #   body: "some body4",
  #   title: "alert4",
  #   to: user6.phone,
  #   from: System.get_env("SYSTEM_ALERT_FROM_SMS")
  # }

  # {:ok, alert} = TurnStile.Alerts.create_alert_w_build_assoc(employee1, user6, a6, rolexy, organization2)
  # TurnStile.Alerts.insert_alert(alert)

  # a7 = %{
  #   alert_category: "initial",
  #   alert_format: "email",
  #   body: "some body2",
  #   title: "alert2",
  #   to: user7.email,
  #   from: System.get_env("SYSTEM_ALERT_FROM_EMAIL")
  # }

  # {:ok, alert} = TurnStile.Alerts.create_alert_w_build_assoc(employee10, user7, a7, role10, organization2)
  # TurnStile.Alerts.insert_alert(alert)

  # a8 = %{
  #   alert_category: "initial",
  #   alert_format: "sms",
  #   body: "some body3",
  #   title: "alert3",
  #   to: user8.phone,
  #   from: System.get_env("SYSTEM_ALERT_FROM_SMS")

  # }

  # {:ok, alert} = TurnStile.Alerts.create_alert_w_build_assoc(employee10, user8, a8, role10, organization2)
  # TurnStile.Alerts.insert_alert(alert)
  # TurnStile.Repo.rollback({:rolling_back})
end)
