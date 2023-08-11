  defmodule TurnStileWeb.UserLive.Index do
  use TurnStileWeb, :live_view
  alias TurnStile.Patients
  alias TurnStile.Patients.User
  alias TurnStile.Staff
  alias TurnStileWeb.EmployeeAuth
  alias TurnStileWeb.AlertUtils
  alias TurnStile.Alerts
  alias TurnStile.Alerts.Alert
  alias TurnStileWeb.UserLive.DisplayListComponent


  # live_actions [:new, :index, :alert, :edit]
  @interval 100000
  @filter_active_users_mins 30

  @impl true
  def mount(_params, session, socket) do
    # TODO - cannot be null
    # get token from session
    employee_token = session["employee_token"]
    # use to get logged in user
    current_employee = Staff.get_employee_by_session_token(employee_token)
    organization_id = current_employee.current_organization_login_id
    # on interval call :update func below
    if connected?(socket), do: Process.send_after(self(), :update, @interval)
    # subscribe - broadcast is in alert controller
    # - delegates to handle_info funcs when called w params
    Phoenix.PubSub.subscribe(TurnStile.PubSub, PubSubTopicsMap.get_topic("STATUS_UPDATE")) # goes to :update
    Phoenix.PubSub.subscribe(TurnStile.PubSub, PubSubTopicsMap.get_topic("STATUS_UPDATE"))
    main_index_users_list = Patients.filter_active_users_x_mins_past_last_update(organization_id, @filter_active_users_mins)
    # IO.inspect(socket.assigns, label: "INDEX: socket.assigns")
    {:ok,
     assign(
      socket,
      search_field_name: nil,
      search_field_value: nil,
      display_message: nil,
      display_instruction: nil,
      existing_users_found: [],
      users: main_index_users_list,
      current_employee: current_employee,
      return_to: Routes.user_index_path(socket, :index, organization_id, current_employee.id)
     )}
  end

  @impl true
  # called via live_patch in index.html; :alert gets assigned as action
  # called on index when no user_id present
  def handle_params(%{"panel" => panel} = params, _url, socket) do
    # IO.inspect(params, label: "action on index")
    # IO.inspect(socket.assigns, label: "action on index")
    socket = assign(socket, :panel, panel)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # called on :display; users list found during :new;
    def handle_params(%{"search_field_name" => _search_field_name, "search_field_value" => _search_field_value} = params, _url, socket) do
      # IO.inspect(params, label: "params on index YYYY")
      # IO.inspect(socket.assigns, label: "params on index YYYY")
    #  socket =
    #   socket
    #   |> assign(:search_field_name, search_field_name)
      {:noreply, apply_action(socket, socket.assigns.live_action, params)}
    end
  # called on :index; this is main index page;
  # called on :search button click
  # called on :display back redirect from handle_info above
  def handle_params( %{"employee_id" => _employee_id, "organization_id" => _organization_id } = params, _url, socket) do
    # back from display
    if Map.get(socket.assigns, :user_changeset) do
      # IO.inspect(socket.assigns.user_changeset.data, label: "params on index XXX")
      {:noreply, apply_action(socket, socket.assigns.live_action, %{"user_changeset" => socket.assigns.user_changeset})}
    else
      # all other calls
      {:noreply, apply_action(socket, socket.assigns.live_action, params)}
    end
  end

  @impl true
  def handle_info(%{user_alert_status: _user_alert_status}, socket) do
     # IO.inspect(user_alert_status, label: "PUBSUB: message in handle_info")

    users =
      Patients.filter_active_users_x_mins_past_last_update(socket.assigns.current_employee.current_organization_login_id, @filter_active_users_mins)

    {:noreply, assign(socket, :users, users)}
  end
  # comes via send :upsert from :new
  def handle_info(%{"existing_users" => existing_users, "user_changeset" => user_changeset}, socket) do

    socket =
      socket
      |> assign(:existing_users, existing_users)
      |> assign(:user_changeset, user_changeset)

    # IO.inspect(socket.assign., label: "PUBSUB EX: message in handle_info")
    IO.inspect(socket.assigns.user_changeset, label: "SEND: message in handle_info")

    {:noreply, socket}
  end
  # pubsub comes thru subscribe in mount
  def handle_info(:update, socket) do
    # update_and_reschedule and call
    if connected?(socket), do: Process.send_after(self(), :update, @interval)
    users =
      Patients.filter_active_users_x_mins_past_last_update(socket.assigns.current_employee.current_organization_login_id, @filter_active_users_mins)

    # IO.inspect(users, label: "update info")
    {:noreply, assign(socket, :users, users)}
  end
  # called from :search; when search results are found
  def handle_info({:users_found, %{"existing_users_found" => existing_users_found}} , socket) do

    # IO.inspect("existing_users_found", label: "UUUU message in handle_info")
    # IO.inspect("UUUUUUUU", label: "message in handle_info")
    # call update to refresh state on :display
    send_update(DisplayListComponent, id: "display")
    {:noreply, assign(socket, :existing_users_found, existing_users_found)}
    # IO.inspect(socket.assigns.existing_users_found, label: "message in handle_info rAFTER")
  end
  # called from :new upsert when existing users are found
  def handle_info({:users_found,
  %{existing_users_found: existing_users_found, user_changeset: user_changeset,
  redirect_to: redirect_to}
  }, socket) do
    socket =
      socket
      |> assign(:existing_users_found, existing_users_found)
      |> assign(:user_changeset, user_changeset)
    # IO.inspect("existing_users_found", label: "message in handle_info")
    # IO.inspect(user_changeset, label: "message in handle_info")
    # IO.inspect("VVVVVVVVVV4", label: "message in handle_info")
      # redirect to :display component
    {:noreply,
      socket
      |> push_patch(to: redirect_to)}
    # {:noreply, socket}
  end
  # called from :display display when going back to original user
  # - redirect back to upsert
  def handle_info({:reject_existing_users,
  %{user_changeset: user_changeset,
  redirect_to: redirect_to}
  }, socket) do
    socket =
      socket
      |> assign(:user_changeset, user_changeset)
    # IO.inspect(socket.assigns.user_changeset.data, label: "message in handle_info")
    # IO.inspect(user_changeset, label: "message in handle_info")
    # IO.inspect("VVVVVVVVVV4", label: "message in handle_info")
      # redirect to :display component
    {:noreply,
      socket
      |> push_patch(to: redirect_to)}
  end
  @impl true
  def handle_event(
        "send_initial_alert",
        %{"alert-format" => alert_format, "user-id" => user_id,
        "value" => _value},
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
            "User not found. Alert not sent. If you are sure this user exists, then a system error has occured."
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
      # no validation errors - proceed with sending alert
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
        |> put_flash(:warning, "User deleted successfully.")

      {:noreply,
       assign(
         socket,
         :users,
         Patients.filter_active_users_x_mins_past_last_update(current_employee.current_organization_login_id, @filter_active_users_mins)
       )}
    else
      socket =
        socket
        |> put_flash(:error, "Insuffient permissions to perform user delete")

      {:noreply,
       assign(
         socket,
         :users,
         Patients.filter_active_users_x_mins_past_last_update(current_employee.current_organization_login_id, @filter_active_users_mins)
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
         Patients.filter_active_users_x_mins_past_last_update(current_employee.current_organization_login_id, @filter_active_users_mins)
       )}
    else
      socket =
        socket
        |> put_flash(:error, "Insuffient permissions to perform user remove")

      {:noreply,
       assign(
         socket,
         :users,
         Patients.filter_active_users_x_mins_past_last_update(current_employee.current_organization_login_id, @filter_active_users_mins)
       )}
    end
  end
   # :alert - renders alert panel
  # -called from when live_patch clicked on index
  defp apply_action(socket, :alert, params) do
    %{"id" => user_id} = params
    # IO.inspect(Patients.get_user(user_id), label: ":alerts")
    socket
    # -applies to index page behind the alert panel
    # - sent as prop through html to panel_component
    |> assign(:user, Patients.get_user(user_id))
  end
  # :new - adding a new user from scratch
  # user is blank map - assign user in upsert update
  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add New User")
    |> assign(:user, %{})
  end
  # :insert - adding a new user that already exists in DB
  # user is formed struct
  defp apply_action(socket, :insert, %{"user_id" => user_id} = _params) do
    socket
    |> assign(:page_title, "Insert Saved User")
    |> assign(:user, Patients.get_user(user_id))
  end
  # :insert - going back from display form
  defp apply_action(socket, :insert, %{"user_changeset" => %Ecto.Changeset{} = user_changeset}) do
    # IO.inspect(user_changeset.data, label: "apply_action on insertAAAA")
    socket
    |> assign(:page_title, "Insert New User")
    |> assign(:user_changeset, user_changeset)
  end
  # :insert - if opened out of sequence with no params; like if route called directly
  defp apply_action(socket, :insert, _params) do
    # IO.inspect(params, label: "apply_action on insertAAAA")
    socket
    |> assign(:page_title, "Insert Saved User")
  end
  # :index - rendering index page
  defp apply_action(socket, :index, _params) do
    # IO.inspect(socket.assigns, label: "apply_action on index")
    socket
      # delete garage data from hanging around
    |> maybe_delete_key(:user_changeset)
    |> maybe_delete_key(:existing_users_found)
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end
  # :search - rendering search page
  defp apply_action(socket, :search, params) do
    # IO.inspect(params, label: "apply_action on search")
    socket
    |> assign(:page_title, "Search for User")
    |> assign(:user, nil)
  end
  # :display - rendering search page displa
  defp apply_action(socket, :display, %{"search_field_name" => search_field_name, "search_field_value" => search_field_value} = params) do
    # IO.inspect(params, label: "apply_action on display")
    # IO.inspect(Map.get(socket.assigns, :user_changeset), label: "apply_action on display")
    socket
    |> assign(:search_field_name, search_field_name)
    |> assign(:search_field_value, search_field_value)
    |> assign(:return_to, Routes.user_index_path(socket, :insert,
    socket.assigns.current_employee.current_organization_login_id,
    socket.assigns.current_employee.id))
    |> assign(:page_title, "Matching Users")
    |> assign(:user_changeset, Map.get(socket.assigns, :user_changeset))
    |> assign(:users, socket.assigns.users)
    |> assign(:existing_users_found, Map.get(socket.assigns, :existing_users_found))
  end

  defp maybe_delete_key(socket, key) do
    if socket.assigns[key] != nil do
      %{
        socket |
        assigns: Map.delete(socket.assigns, key)
      }
    else
      socket
    end
  end
end
