defmodule TurnStileWeb.UserLive.Index do
  use TurnStileWeb, :live_view
  alias TurnStile.Patients
  alias TurnStile.Patients.User
  alias TurnStile.Staff
  alias TurnStileWeb.EmployeeAuth
  alias TurnStileWeb.AlertUtils
  alias TurnStile.Alerts
  alias TurnStile.Alerts.Alert

  @interval 10000

  @alert_update_status PubSubTopicsMap.get_topic("STATUS_UPDATE")
  @interval 10000
  @impl true
  def mount(_params, session, socket) do
    # TODO - cannot be null
    # get token from session
    employee_token = session["employee_token"]
    # use to get logged in user
    current_employee = Staff.get_employee_by_session_token(employee_token)
    organization_id = current_employee.current_organization_login_id
    # on interval call :update func below
    # if connected?(socket), do: Process.send_after(self(), :update, @interval)
    # subscribe - broadcast is in alert controller
    Phoenix.PubSub.subscribe(TurnStile.PubSub, PubSubTopicsMap.get_topic("STATUS_UPDATE"))

    {:ok,
     assign(
       socket,
       users: Patients.list_active_users(organization_id),
       current_employee: current_employee
     )}
  end

  @impl true
  # called on index when no user_id
  def handle_params(%{"panel" => panel} = params, _url, socket) do
    # IO.inspect(params, label: "action on index")
    socket = assign(socket, :panel, panel)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # called on show when user_id
  def handle_params(params, _url, socket) do
    # IO.inspect(params, label: "params on index")
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true

  def handle_info(%{user_alert_status: user_alert_status}, socket) do
    IO.inspect(user_alert_status, label: "message in handle_info")

    users =
      Patients.list_active_users(socket.assigns.current_employee.current_organization_login_id)

    {:noreply, assign(socket, :users, users)}
  end

  def handle_info(:update_and_reschedule, socket) do
    IO.puts("calling :update_and_reschedule")
    Process.send_after(self(), :update, @interval)

    users =
      Patients.list_active_users(socket.assigns.current_employee.current_organization_login_id)

    # IO.inspect(users, label: "XXXXXXXX")
    {:noreply, assign(socket, :users, users)}
  end

  def handle_info(:update, socket) do
    IO.inspect(:update, label: "PubSub update")
    Process.send_after(self(), :update, @interval)

    # Process.send(self(), :update, 30000)
    users =
      Patients.list_active_users(socket.assigns.current_employee.current_organization_login_id)

    # IO.inspect(users, label: "YYYYYYY")
    {:noreply, assign(socket, :users, users)}
  end

  @impl true
  def handle_event(
        "send_initial_alert",
        %{"alert-format" => alert_format, "user-id" => user_id, "value" => _value},
        socket
      ) do
    # assign user to socket to pass along
    socket = assign(socket, :user, Patients.get_user(user_id))
    # error checking conditions
    cond do
      # check user is not nil
      !Map.get(socket.assigns, :user) ->
        {
          :noreply,
          socket
          |> put_flash(
            :error,
            "No user found. Alert not sent. If user exists, then a system error occured."
          )
        }

      # check not missing phone
      alert_format === AlertFormatTypesMap.get_alert("SMS") &&
          !Map.get(socket.assigns.user, :phone) ->
        {
          :noreply,
          socket
          |> put_flash(
            :error,
            "Default alert type is set to SMS but user phone number is missing. Add user phone number to send SMS alert."
          )
        }

      alert_format === AlertFormatTypesMap.get_alert("EMAIL") &&
          !Map.get(socket.assigns.user, :email) ->
        {
          :noreply,
          socket
          |> put_flash(
            :error,
            "Default alert type is set to email but user email is missing. Add user email to send email alert."
          )
        }

      true ->
        attrs =
          Alerts.build_alert_attrs(
            socket.assigns.user,
            AlertCategoryTypesMap.get_alert("INITIAL"),
            alert_format
          )

        # IO.inspect(attrs, label: "attrs in handle_event")
        changeset = Alerts.create_new_alert(%Alert{}, attrs)
        # IO.inspect(changeset, label: "changeset in handle_event")
        case AlertUtils.authenticate_and_save_sent_alert(socket, changeset, %{}) do
          {:ok, alert} ->
            if alert.alert_format == AlertFormatTypesMap.get_alert("EMAIL") do
              case AlertUtils.send_email_alert(alert) do
                {:ok, _email_msg} ->

                  case AlertUtils.handle_updating_user_alert_send_status(
                    socket.assigns.user,
                    AlertCategoryTypesMap.get_alert("INITIAL")) do
                    {:ok, _user} ->
                      # call :update for DB/page updates
                      if connected?(socket), do: Process.send(self(), :update, [:noconnect])

                      # IO.inspect(List.last(socket.assigns.users), label: "users in fetchBBBBBBBBBBBBB")
                      {
                        :noreply,
                        socket
                        |> put_flash(:success, "Alert sent successfully")
                      }

                    {:error, error} -> # handle_updating_user_alert_send_status error
                    IO.inspect(error, label: "email index alert error in handle_event")
                      {
                        :noreply,
                        socket
                        |> put_flash(:error, "Failure in alert send. #{error}")
                      }
                  end

                {:error, error} -> # system/mailgun SMS error
                  # delete saved alert due to send error
                  Alerts.delete_alert(alert)
                  # handle mailgun error format
                  IO.inspect(error, label: "SMS index alert error in handle_event")
                  case error do
                    {error_code, %{"message" => error_message}} ->
                      {
                        :noreply,
                        socket
                        |> put_flash(:error, "Failure in alert send. #{error_message}. Code: #{error_code}")
                      }
                    _ ->
                      {
                        :noreply,
                        socket
                        |> put_flash(:error, "Failure in email alert send.")
                      }
                  end
              end
            else
              case AlertUtils.send_SMS_alert(alert) do
                {:ok, twilio_msg} ->
                  IO.inspect(twilio_msg, label: "twilio_msg")

                  case AlertUtils.handle_updating_user_alert_send_status(
                         socket.assigns.user,
                         AlertCategoryTypesMap.get_alert("INITIAL")
                       ) do
                    {:ok, _user} ->
                      # call :update for DB/page updates
                      if connected?(socket), do: Process.send(self(), :update, [:noconnect])

                      # IO.inspect(List.last(socket.assigns.users), label: "users in fetchBBBBBBBBBBBBB")
                      {
                        :noreply,
                        socket
                        |> put_flash(:success, "Alert sent successfully")
                      }

                    {:error, error} ->
                      {
                        :noreply,
                        socket
                        |> put_flash(:error, "Failure in alert send. #{error}")
                      }
                  end

                # handle twilio errors
                {:error, error_map, error_code} ->
                  # delete saved alert due to send error
                  Alerts.delete_alert(alert)

                  {
                    :noreply,
                    socket
                    |> put_flash(
                      :error,
                      "Failure in alert send. #{error_map["message"]}. Code: #{error_code}"
                    )
                  }

                {:error, error} -> # system SMS error
                  # delete saved alert due to send error
                  Alerts.delete_alert(alert)

                  {
                    :noreply,
                    socket
                    |> put_flash(:error, "Failure in alert send. #{error}")
                  }
              end
            end


          {:error, error} -> # authenticate_and_save_sent_alert error
            IO.inspect(error, label: "error in handle_event authenticate_and_save_sent_aler")

            socket =
              socket
              |> put_flash(:error, "Initial SMS alert failed to send: #{error}")

            {:noreply, socket}
        end
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    current_employee = socket.assigns.current_employee

    if EmployeeAuth.has_user_delete_permissions?(socket, current_employee) do
      user = Patients.get_user(id)
      {:ok, _} = Patients.delete_user(user)

      socket =
        socket
        |> put_flash(:info, "User deleted successfully.")

      {:noreply,
       assign(
         socket,
         :users,
         Patients.list_active_users(current_employee.current_organization_login_id)
       )}
    else
      socket =
        socket
        |> put_flash(:error, "Insuffient permissions to perform user delete")

      {:noreply,
       assign(
         socket,
         :users,
         Patients.list_active_users(current_employee.current_organization_login_id)
       )}
    end
  end

  def handle_event("remove", %{"id" => id}, socket) do
    current_employee = socket.assigns.current_employee

    if EmployeeAuth.has_user_remove_permissions?(socket, current_employee) do
      user = Patients.get_user(id)
      Patients.deactivate_user(user)

      socket =
        socket
        |> put_flash(:info, "User inactivated.")

      {:noreply,
       assign(
         socket,
         :users,
         Patients.list_active_users(current_employee.current_organization_login_id)
       )}
    else
      socket =
        socket
        |> put_flash(:error, "Insuffient permissions to perform user remove")

      {:noreply,
       assign(
         socket,
         :users,
         Patients.list_active_users(current_employee.current_organization_login_id)
       )}
    end
  end

  defp apply_action(socket, :alerts, params) do
    %{"id" => user_id} = params
    # IO.inspect(Patients.get_user(user_id), label: "user_id")
    socket
    |> assign(:page_title, "User Alerts")
    |> assign(:user, Patients.get_user(user_id))
  end

  defp apply_action(socket, :edit_all, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Patients.get_user(id))
  end

  # assigns individual user changset on :new
  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    # IO.inspect("index", label: "apply_action on index")
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end
end
