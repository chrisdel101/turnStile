TurnStile.Repo.transaction(fn ->
  org1_params = %{
    email: "org1@test.com",
    name: "Org1",
    phone: "777777777",
    slug: "org1"
  }
  {:ok, organization1} = TurnStile.Company.insert_and_preload_organization(org1_params)
  em1 = %{
    email: "sam1@jones.com",
    email_confirmation: "sam1@jones.com",
    last_name: "Jones1",
    first_name: "Sam",
    password: "password",
    password_confirmation: "password"
  }
  {:ok, employee1} = TurnStile.Staff.insert_register_employee(em1, organization: organization1)
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

  em2 = %{
    email: "sam2@jones.com",
    email_confirmation: "sam2@jones.com",
    last_name: "Jones2",
    first_name: "Sam",
    password: "password",
    password_confirmation: "password"
  }
  {:ok, employee2} = TurnStile.Staff.insert_register_employee(em2, organization: organization1)
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

  em3 = %{
    email: "joe4@schmo.com",
    email_confirmation: "joe4@schmo.com",
    first_name: "Joe",
    last_name: "Schmo4",
    password: "password",
    password_confirmation: "password"
  }
  {:ok, employee4} = TurnStile.Staff.insert_register_employee(em3, organization: organization1)
  {:ok, org_w_emps} = TurnStile.Company.update_employee_assoc(organization1, employee4)
  role =
    TurnStile.Roles.build_role(%{
      name: EmployeeRolesMap.get_permission_role("ADMIN"),
      value: to_string(EmployeeRolesMap.get_permission_role_value("ADMIN"))
    })
  # add has_many role assocations
  role = TurnStile.Roles.assocaiate_role_with_employee(role, employee4)
  role = TurnStile.Roles.assocaiate_role_with_organization(role, org_w_emps)
  TurnStile.Roles.insert_role(employee4.id, org_w_emps.id, role)

  user1 = %{
    first_name: "Bobby",
    last_name: "joe",
    email: "bobby1@sjoe.com",
    phone: "777777777",
    health_card_num: 1234
  }

  {:ok, user1} = TurnStile.Patients.create_user_w_assocs(employee1, user1, organization1)

  user2 = %{
    first_name: "Bobby",
    last_name: "joe2",
    email: "bobby2@sjoe.com",
    phone: "777777777",
    health_card_num: 5678
  }

  # user w/ emp and org assocs
  {:ok, user2} = TurnStile.Patients.create_user_w_assocs(employee2, user2, organization1)

  user3 = %{
    first_name: "Bobby",
    last_name: "joe3",
    email: "bobby3@sjoe.com",
    phone: "777777777",
    health_card_num: 9101
  }

  # user w/ emp and org assocs
  {:ok, user3} = TurnStile.Patients.create_user_w_assocs(employee4, user3, organization1)

  user4 = %{
    first_name: "Bobby",
    last_name: "joe4",
    email: "bobb41@sjoe.com",
    phone: "777777777",
    health_card_num: 1121
  }

  # user w/ emp and org assocs
  {:ok, user4} = TurnStile.Patients.create_user_w_assocs(employee1, user4, organization1)

  {:ok, user1} = TurnStile.Repo.insert(user1)
  {:ok, user2} = TurnStile.Repo.insert(user2)
  {:ok, user3} = TurnStile.Repo.insert(user3)
  {:ok, user4} = TurnStile.Repo.insert(user4)

  a1 = %{
    alert_category: AlertCategoryTypesMap.get_alert("INITIAL"),
    alert_format: AlertFormatTypesMap.get_alert("SMS"),
    body: "some body1",
    title: "alert1"
  }

  {:ok, alert} = TurnStile.Alerts.create_alert_w_assoc(employee1, user1, a1)
  TurnStile.Alerts.insert_alert(alert)

  a4 = %{
    alert_category: AlertCategoryTypesMap.get_alert("CONFIRMATION"),
    alert_format: "sms",
    body: "some body4",
    title: "alert4"
  }

  {:ok, alert} = TurnStile.Alerts.create_alert_w_assoc(employee2, user1, a4)
  TurnStile.Alerts.insert_alert(alert)

  a2 = %{
    alert_category:  AlertCategoryTypesMap.get_alert("INITIAL"),
    alert_format: AlertFormatTypesMap.get_alert("SMS"),
    body: "some body2",
    title: "alert2"
  }

  {:ok, alert} = TurnStile.Alerts.create_alert_w_assoc(employee1, user1, a2)
  TurnStile.Alerts.insert_alert(alert)

  a3 = %{
    alert_category: AlertCategoryTypesMap.get_alert("INITIAL"),
    alert_format: AlertFormatTypesMap.get_alert("SMS"),
    body: "some body3",
    title: "alert3"
  }

  {:ok, alert} = TurnStile.Alerts.create_alert_w_assoc(employee1, user1, a3)
  TurnStile.Alerts.insert_alert(alert)

  # ORG 2
  org2_params = %{
    email: "org2@test.com",
    name: "Org2",
    phone: "777777777",
    slug: "org2"
  }

  {:ok, organization2} = TurnStile.Company.insert_and_preload_organization(org2_params)

  em1 = %{
    email: "joe3@schmo.com",
    email_confirmation: "joe3@schmo.com",
    first_name: "Joe",
    last_name: "Schmo",
    password: "password",
    password_confirmation: "password"
  }
  {:ok, employee3} = TurnStile.Staff.insert_register_employee(em1, organization: organization2)
  {:ok, org_w_emps} = TurnStile.Company.update_employee_assoc(organization2, employee3)
  role =
    TurnStile.Roles.build_role(%{
      name: EmployeeRolesMap.get_permission_role("OWNER"),
      value: to_string(EmployeeRolesMap.get_permission_role_value("OWNER"))
    })
  # add has_many role assocations
  role = TurnStile.Roles.assocaiate_role_with_employee(role, employee3)
  role = TurnStile.Roles.assocaiate_role_with_organization(role, org_w_emps)
  TurnStile.Roles.insert_role(employee3.id, org_w_emps.id, role)

  # add existing employee to org2
  {:ok, org_w_emps} = TurnStile.Company.update_employee_assoc(organization2, employee2)
  role =
    TurnStile.Roles.build_role(%{
      name: EmployeeRolesMap.get_permission_role("ADMIN"),
      value: to_string(EmployeeRolesMap.get_permission_role_value("ADMIN"))
    })
  role = TurnStile.Roles.assocaiate_role_with_employee(role, employee2)
  role = TurnStile.Roles.assocaiate_role_with_organization(role, org_w_emps)
  TurnStile.Roles.insert_role(employee2.id, org_w_emps.id, role)

  user5 = %{
    first_name: "Bobby",
    last_name: "joe5",
    email: "bobby5@sjoe.com",
    phone: "777777777",
    health_card_num: 3141
  }
# IO.inspect(user1)
  {:ok, user5} = TurnStile.Patients.create_user_w_assocs(employee1, user5, organization2)

  user6 = %{
    first_name: "Bobby",
    last_name: "joe6",
    email: "bobby6@sjoe.com",
    phone: "777777777",
    health_card_num: 5161
  }

  # user w/ emp and org assocs
  {:ok, user6} = TurnStile.Patients.create_user_w_assocs(employee2, user6, organization2)

  user7 = %{
    first_name: "Bobby",
    last_name: "joe7",
    email: "bobby7@sjoe.com",
    phone: "777777777",
    health_card_num: 7181
  }

  # user w/ emp and org assocs
  {:ok, user7} = TurnStile.Patients.create_user_w_assocs(employee1, user7, organization2)

  user8 = %{
    first_name: "Bobby",
    last_name: "joe8",
    email: "bobby8@sjoe.com",
    phone: "777777777",
    health_card_num: 9202
  }

  # user w/ emp and org assocs
  {:ok, user8} = TurnStile.Patients.create_user_w_assocs(employee2, user8, organization2)

  {:ok, user5} = TurnStile.Repo.insert(user5)
  {:ok, user6} = TurnStile.Repo.insert(user6)
  {:ok, user7} = TurnStile.Repo.insert(user7)
  {:ok, user8} = TurnStile.Repo.insert(user8)

  a1 = %{
    alert_category: AlertCategoryTypesMap.get_alert("INITIAL"),
    alert_format: AlertFormatTypesMap.get_alert("SMS"),
    body: "some body1",
    title: "alert1"
  }

  {:ok, alert} = TurnStile.Alerts.create_alert_w_assoc(employee1, user5, a1)
  TurnStile.Alerts.insert_alert(alert)

  a4 = %{
    alert_category: AlertCategoryTypesMap.get_alert("CONFIRMATION"),
    alert_format: "sms",
    body: "some body4",
    title: "alert4"
  }

  {:ok, alert} = TurnStile.Alerts.create_alert_w_assoc(employee1, user5, a4)
  TurnStile.Alerts.insert_alert(alert)

  a2 = %{
    alert_category:  AlertCategoryTypesMap.get_alert("INITIAL"),
    alert_format: AlertFormatTypesMap.get_alert("SMS"),
    body: "some body2",
    title: "alert2"
  }

  {:ok, alert} = TurnStile.Alerts.create_alert_w_assoc(employee2, user6, a2)
  TurnStile.Alerts.insert_alert(alert)

  a3 = %{
    alert_category: AlertCategoryTypesMap.get_alert("INITIAL"),
    alert_format: AlertFormatTypesMap.get_alert("SMS"),
    body: "some body3",
    title: "alert3"
  }

  {:ok, alert} = TurnStile.Alerts.create_alert_w_assoc(employee2, user8, a3)
  TurnStile.Alerts.insert_alert(alert)


  # TurnStile.Repo.rollback({:rolling_back})
end)
