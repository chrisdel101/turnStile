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
    role_value_on_current_organization:
      to_string(EmployeeRolesMap.get_permission_role_value("owner")),
    role_on_current_organization: EmployeeRolesMap.get_permission_role("OWNER"),
    timezone: "America/New_York"
  }
  # insert emp w 3 preload
  {:ok, employee1} = TurnStile.Staff.insert_register_and_preload_employee(ex2, organization1)

  user_params = %{
    first_name: "Joe2",
    last_name: "Schmoe",
    email: "joe2@schmoe.com",
    phone: "777777777",
    health_card_num: 5678
  }
  # user w/ emp and org assocs
  {:ok, user} = TurnStile.Patients.create_user_w_assocs(employee1, user_params, organization1)

  {:ok, user_insert} = TurnStile.Repo.insert(user)
  # build org changeset
  org_changeset = TurnStile.Company.Organization.changeset(%TurnStile.Company.Organization{} = organization1, %{})

# add assocations to org
  org_with_emps =
    org_changeset
    |> Ecto.Changeset.put_assoc(:employees, [employee1])
    |> Ecto.Changeset.put_assoc(:users, [user_insert])

#  update org table
  {:ok, organization1} = TurnStile.Company.update_organization_changeset(org_with_emps)

  IO.inspect(organization1)

  a1 = %{
    alert_category: "initial",
    alert_format: "sms",
    body: "some body1",
    title: "alert1"
  }
  {:ok, alert} = TurnStile.Alerts.create_alert_w_assoc(employee1, user_insert, a1)
  IO.inspect(alert)
  TurnStile.Alerts.insert_alert(alert)

  TurnStile.Repo.rollback({:rolling_back})
end)
