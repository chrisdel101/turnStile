defmodule TurnStile.Alerts do
  @moduledoc """
  The Alerts context.
  """

  import Ecto.Query, warn: false
  alias TurnStile.Repo

  alias TurnStile.Alerts.Alert
  alias TurnStile.Alerts.AlertToken
  alias TurnStile.Patients
  alias TurnStile.Staff
  alias TurnStile.Roles
  @json TurnStile.Utils.read_json("sms.json")

  @doc """
  Returns the list of alerts.

  ## Examples

      iex> list_alerts()
      [%Alert{}, ...]

  """
  def list_alerts do
    raise "TODO"
  end

  @doc """
  Gets a single alert.

  Raises if the Alert does not exist.

  ## Examples

      iex> get_alert!(123)
      %Alert{}

  """
  def get_alert(id) do
    Repo.get(Alert, id)
  end

  def get_alerts_for_user(user_id) do
    query =
      from(a in Alert,
        where: a.user_id == ^user_id,
        order_by: [desc: a.inserted_at]
      )

    Repo.all(query)
  end

  @doc """
  create_new_alert
  Creates a new alert object for use in insertion process.
  """
  def create_new_alert(%Alert{} = alert, attrs \\ %{}, validate? \\ false) do
    Alert.changeset(alert, attrs, validate?)
  end

  @doc """
  create_alert_w_build_assoc
  -takes an alert struct
  -uses build_assoc adding assocs
  -returns alert_struct w assocs
  """
  def create_alert_w_build_assoc(
        employee_struct,
        user_struct,
        attrs,
        role,
        organization_struct \\ nil
      ) do
    # build alert instance
    alert = %Alert{
      alert_category: attrs["alert_category"] || attrs.alert_category,
      alert_format: attrs["alert_format"] || attrs.alert_format,
      body: attrs["body"] || attrs.body,
      title: attrs["title"] || attrs.title,
      to: attrs["to"] || attrs.to,
      from: attrs["from"] || attrs.from
    }

    # build_alert assoc
    alert_struct = Ecto.build_assoc(user_struct, :alerts, alert)
    #  check employee organization_struct
    case employee_struct.current_organization_login_id do
      # check employee has org_id, or ir org struct passed in
      nil ->
        case organization_struct do
          nil ->
            error =
              "Error: create_alert_w_build_assoc: User.organization struct && organization params cannot BOTH be nil. Organization is required."

            IO.puts(error)
            {:error, error}

          _ ->
            # check all assocs are okay
            case Roles.check_role_has_employee_org_asocc_and_user_org_assoc(
                   employee_struct.id,
                   organization_struct.id,
                   user_struct,
                   role
                 ) do
              {:error, error} ->
                IO.puts(error)
                {:error, error}

              # check employee as permissions
              {:ok, _} ->
                if Roles.role_has_send_alert_permission?(role) do
                  alert_struct = Ecto.build_assoc(employee_struct, :alerts, alert_struct)
                  alert_struct = Ecto.build_assoc(organization_struct, :alerts, alert_struct)
                  # alert_struct
                  {:ok, alert_struct}
                else
                  {:error, "Employee lacks permissions to add alerts"}
                end
            end
        end

      # if logged-in user
      _ ->
        organization_id = employee_struct.current_organization_login_id
        organization_struct = TurnStile.Company.get_organization(organization_id)

        case Roles.check_role_has_employee_org_asocc_and_user_org_assoc(
               employee_struct.id,
               organization_id,
               user_struct,
               role
             ) do
          {:error, error} ->
            IO.puts(error)
            {:error, error}

          # check employee as permissions
          {:ok, _} ->
            if Roles.role_has_send_alert_permission?(role) do
              alert_struct = Ecto.build_assoc(employee_struct, :alerts, alert_struct)
              alert_struct = Ecto.build_assoc(organization_struct, :alerts, alert_struct)
              # alert_struct
              {:ok, alert_struct}
            else
              {:error, "Employee lacks permissions to add alerts"}
            end
        end
    end
  end

  @doc """
  create_alert_w_put_assoc
  -builds sets of changeset with put_assoc
  -returns formed alert changeset
  -takes alert_attrs or changeset in opts like [alert_attrs: %{}, changeset: %{}]
  """
  def create_alert_w_put_assoc(
        employee_struct,
        user_struct,
        opts \\ []
      ) do
    if is_nil(Keyword.get(opts, :alert_attrs)) &&
         is_nil(Keyword.get(opts, :changeset)) do
      error = "Opts CANNOT be nil. Pass in alert_attrs or changeset."
      IO.puts("Error in create_alert_w_put_assoc: #{error}")
      {:error, "An error occurred creating alert associations. #{error}"}
    else
      # build_alert assoc - takes params or a changeset
      alert = Alert.changeset(Keyword.get(opts, :changeset), Keyword.get(opts, :alert_attrs))
      # IO.inspect(alert, label: "alert changeset create_alert_w_put_assoc")

      changeset_with_user = Ecto.Changeset.put_assoc(alert, :user, user_struct)

      # For logged in employee: use organization_struct
      case employee_struct.current_organization_login_id do
        #  non-logged in user requires organization struct
        nil ->
          organization_struct = Keyword.get(opts, :organization_struct)

          case organization_struct do
            nil ->
              error =
                "Error: cast_alert_changeset: User.organization struct && organization params cannot BOTH be nil. Organization is required."

              IO.puts(error)
              {:error, error}

            _ ->
              # add other assoc
              changeset_with_employee =
                Ecto.Changeset.put_assoc(changeset_with_user, :employee, employee_struct)

              changeset_with_organization =
                Ecto.Changeset.put_assoc(
                  changeset_with_employee,
                  :organization,
                  organization_struct
                )

              # alert_struct
              {:ok, changeset_with_organization}
          end

        # if logged-in user
        _ ->
          organization_id = employee_struct.current_organization_login_id
          organization_struct = TurnStile.Company.get_organization(organization_id)

          changeset_with_employee =
            Ecto.Changeset.put_assoc(changeset_with_user, :employee, employee_struct)

          changeset_with_organization =
            Ecto.Changeset.put_assoc(
              changeset_with_employee,
              :organization,
              organization_struct
            )

          {:ok, changeset_with_organization}
      end
    end
  end

  def insert_alert(alert) do
    # a = Alert.changeset(alert, %{})
    # a = Map.put(a, :error, "Some Error")
    # {:error, a}
    Repo.insert(alert)
  end

  @doc """
  insert_alert_w_assoc
   Creates new alert changset with assoc to user & employee.
   DB insertion
  """
  def insert_alert_w_assoc(employee_id, user_id, attrs) do
    user = Patients.get_user(user_id)
    employee = Staff.get_employee(employee_id)

    if !user || !employee do
      {:error, "User or Employee not found for alert creation"}
    else
      # build_assoc to both user & employee
      alert_assoc = Ecto.build_assoc(user, :alerts, employee_id: employee.id)
      alert = create_new_alert(alert_assoc, attrs)
      Repo.insert(alert)
    end
  end

  @doc """
  build_alert_attr
  -CUSTOM: takes user input from form; or fills in with defaults
  -INITIAL: uses values set in json file
  -use env variables to set system :from fields
  -Returns a map of alert attributes
  -to override default fields pass in opts [:body, :title, :from...]
  """
  def build_alert_attrs(
        user,
        alert_category,
        alert_format \\ AlertFormatTypesMap.get_alert("SMS"),
        opts \\ []
      ) do
    cond do
      # build custom type alert
      alert_category === AlertCategoryTypesMap.get_alert("CUSTOM") ->
        %{
          title:
              case Keyword.get(opts, :title) do
                value -> value
              end,
          # allow empty body for user form entry for email
          body:
              case Keyword.get(opts, :body) do
                value ->
                  value
            end,
          from:
            case Keyword.get(opts, :from) do
              nil ->
                cond do
                  alert_format === AlertFormatTypesMap.get_alert("EMAIL") ->
                    System.get_env("SYSTEM_ALERT_FROM_EMAIL")

                  true ->
                    System.get_env("SYSTEM_ALERT_FROM_SMS")
                end
              value ->
                value
            end,
          to:
            case Keyword.get(opts, :to) do
              nil ->
                cond do
                  alert_format === AlertFormatTypesMap.get_alert("EMAIL") ->
                    user.email
                  true ->
                    user.phone
                end
              value ->
                value
            end,
          alert_format: alert_format,
          alert_category: alert_category
        }

      #  INITIAL is only SMS type
      alert_category === AlertCategoryTypesMap.get_alert("INITIAL") ->
        %{
          title: @json["alerts"]["request"]["initial"]["title"],
          body: @json["alerts"]["request"]["initial"]["body"],
          from: System.get_env("SYSTEM_ALERT_FROM_SMS"),
          to: user.phone,
          alert_format: alert_format,
          alert_category: alert_category
        }
      (alert_category === AlertCategoryTypesMap.get_alert("CONFIRMATION") ||  alert_category === AlertCategoryTypesMap.get_alert("CANCELLATION")) ->
        %{
          title: Keyword.get(opts, :title),
          body: Keyword.get(opts, :body),
          from: Keyword.get(opts, :from),
          to: Keyword.get(opts, :to),
          alert_format: alert_format,
          alert_category: alert_category
        }
      # test map
      true ->
        %{
          title: @json["alerts"]["request"]["custom"]["dev_test"]["title"],
          body: @json["alerts"]["request"]["custom"]["dev_test"]["body"],
          from: System.get_env("SYSTEM_ALERT_FROM_SMS"),
          to: System.get_env("TEST_NUMBER"),
          alert_format: alert_format,
          alert_category: alert_category
        }
    end
  end

  @doc """
  Updates a alert.

  ## Examples

      iex> update_alert(alert, %{field: new_value})
      {:ok, %Alert{}}

      iex> update_alert(alert, %{field: bad_value})
      {:error, ...}

  """
  def update_alert(%Alert{} = alert, attrs) do
    Alert.changeset(alert, attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Alert.

  ## Examples

      iex> delete_alert(alert)
      {:ok, %Alert{}}

      iex> delete_alert(alert)
      {:error, ...}

  """
  def delete_alert(%Alert{} = alert) do
    raise "TODO"
  end

  @doc """
  Returns a data structure for tracking alert changes.

  ## Examples

      iex> change_alert(alert)
      %Todo{...}

  """
  def change_alert(%Alert{} = alert, attrs \\ %{}, validate? \\ false) do
    Alert.changeset(alert, attrs, validate?)
  end

  def generate_alert_cookie_token(alert) do
    {token, alert_token} = AlertToken.build_cookie_token(alert)
    Repo.insert(alert_token)
    token
  end

end
