  defmodule TurnStileWeb.UserLive.Index do
  use TurnStileWeb, :live_view
  import Ecto.Changeset

  alias TurnStile.Patients
  alias TurnStile.Patients.UserToken
  alias TurnStile.Staff
  alias TurnStileWeb.EmployeeAuth
  alias TurnStileWeb.AlertUtils
  alias TurnStile.Alerts
  alias TurnStile.Alerts.Alert
  alias TurnStileWeb.UserLive.DisplayListComponent
  @dialyzer {:no_match, save_user: 3}
  @user_search_fields [:email, :phone, :last_name, :health_card_num]


  # live_actions [:new, :index, :alert, :edit]
  @interval 100000
  @filter_active_users_mins 30
  @wait_time_mins 60
  # @dialyzer {:nowarn_function, handle_event: 3}
  @dialyzer {:no_match, handle_event: 3}


  @impl true
  def mount(_params, session, socket) do
    # TODO - cannot be null
    # get token from session
    employee_token = session["employee_token"]
    # use to get logged in user
    current_employee = Staff.get_employee_by_session_token(employee_token)
    organization_id = current_employee && current_employee.current_organization_login_id
    # on interval call :update func below
    if connected?(socket), do: Process.send_after(self(), :update, @interval)
    # subscribe - broadcast is in alert controller
    # - delegates to handle_info funcs when called w params
    Phoenix.PubSub.subscribe(TurnStile.PubSub, PubSubTopicsMap.get_topic("STATUS_UPDATE")) # goes to :update
    Phoenix.PubSub.subscribe(TurnStile.PubSub, PubSubTopicsMap.get_topic("USER_REGISTRATION")) # goes to :handle_info
    main_index_users_list = Patients.filter_active_users_x_mins_past_last_update(organization_id, @filter_active_users_mins)
    # IO.inspect(socket.assigns, label: "INDEX: socket.assigns")
    {:ok,
     assign(
      socket,
      toggle_popup: true,
      user_registration_messages: [%{"0" => %{
        first_name: "Joe",
        last_name: "Schmoe",
        phone: "3065190138",
        email: "arssonist@yahoo.com",
        alert_format_set: "email",
        health_card_num: 9999,
        date_of_birth: Date.from_iso8601!("1900-01-01")
      }}, %{"1" => %{
        first_name: "Joe",
        last_name: "Schmoe2",
        phone: "3065190139",
        email: "blah@yahoo.com",
        alert_format_set: "email",
        health_card_num: 1234,
        date_of_birth: Date.from_iso8601!("1900-01-01")
      }}],
      code: maybe_assign_code(socket, nil),
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
    # called on :select: back from :display_existing_user
    def handle_params( %{"employee_id" => _employee_id, "organization_id" => _organization_id, "user_id" => _user_id } = params, _url, socket) do
      # IO.inspect(user_id, label: "handle_params main index:back from display")
      # all other calls
      {:noreply, apply_action(socket, socket.assigns.live_action, params)}
    end
    # called on :index - main index render
    # called on :search button click
    def handle_params( %{"employee_id" => _employee_id, "organization_id" => _organization_id } = params, _url, socket) do
      if Map.get(socket.assigns, :user_changeset) do
        # back action from from display "Add Original User"
        # IO.inspect(socket.assigns, label: "handle_params main index: w changeset")
        # IO.inspect(socket.assigns.live_action, label: "handle_params main index: w changeset")
        {:noreply, apply_action(socket, socket.assigns.live_action, %{"user_changeset" => socket.assigns[:user_changeset]})}
      else
        # IO.inspect(params, label: "handle_params main index: no changeset")
        # all other calls
        {:noreply, apply_action(socket, socket.assigns.live_action, params)}
      end
    end

  @impl true
  def handle_info(%{user_alert_status: user_alert_status}, socket) do
     IO.inspect(user_alert_status, label: "PUBSUB: message in handle_info")

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
    # IO.inspect(socket.assigns.user_changeset, label: "SEND: message in handle_info")

    {:noreply, socket}
  end
  # pubsub comes thru subscribe in mount
  def handle_info(:update, socket) do
    IO.puts("index handle info: :update")
    # update_and_reschedule and call
    if connected?(socket), do: Process.send_after(self(), :update, @interval)
    users =
      Patients.filter_active_users_x_mins_past_last_update(socket.assigns.current_employee.current_organization_login_id, @filter_active_users_mins)

    # IO.inspect(users, label: "update info")
    {:noreply, assign(socket, :users, users)}
  end
  # called from :search; when search results are found
  def handle_info({:users_found, %{"existing_users_found" => existing_users_found}} , socket) do

    IO.puts("index handle info: {:users_found, %{'existing_users_found' => existing_users_found}}")
    # IO.inspect("UUUUUUUU", label: "message in handle_info")
    # call update to refresh state on :display
    send_update(DisplayListComponent, id: "display")
    {:noreply, assign(socket, :existing_users_found, existing_users_found)}
    # IO.inspect(socket.assigns.existing_users_found, label: "message in handle_info rAFTER")
  end
  # called from :new upsert send(); when existing users are found this sent back
  # redirect to display component
  def handle_info({:users_found,
  %{existing_users_found: existing_users_found, user_changeset: user_changeset,
  redirect_to: redirect_to}
  }, socket) do
    socket =
      socket
      |> assign(:existing_users_found, existing_users_found)
      |> assign(:user_changeset, user_changeset)
    IO.puts("index handle_info: sent from upsert send(): changeset and ext users")
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
    IO.inspect(user_changeset, label: "message in handle_info")
    # IO.inspect("VVVVVVVVVV4", label: "message in handle_info")
      # redirect to :display component
    {:noreply,
      socket
      |> push_patch(to: redirect_to)}
    end
  def handle_info({:user_registation_form, %{user_params: user_params}}, socket) do
    index = length(socket.assigns.user_registration_messages)
    currrent_message = %{index => user_params}
    # add incoming message to storage
    messages = Enum.concat(socket.assigns.user_registration_messages, [currrent_message])
    {:noreply, socket
    |> assign(:user_registration_messages, messages)}
  end
  @impl true
  def handle_event("user_registration_accept", params, socket
  ) do
    # get id from button value field
    message_id = params["value"]
    # match id to msg key id
    message = Enum.find(socket.assigns.user_registration_messages, fn msg -> Map.keys(msg) === [message_id] end)
    #send msg to upsert form
    user_params = Map.values(message)
    {:ok, user_params} = Enum.fetch(user_params, 0)
    IO.inspect(message, label: "user_registration_accept")
    # build new user
    changeset = Patients.create_user(user_params)
    IO.inspect(changeset, label: "user_registration_accept")
    # apply_action(socket, :insert, %{"user_changeset" => changeset})
    {:noreply,
    socket
    |> assign(:live_action, :insert)
    |> apply_action(:insert, %{"user_changeset" => changeset})}
    end
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

            if alert.alert_format === AlertFormatTypesMap.get_alert("EMAIL") do
              case AlertUtils.send_email_alert(alert) do
                {:ok, _email_msg} ->
                  # IO.inspect(email_msg, label: "email_msgXXX")
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
                {:ok, _twilio_msg} ->
                  # IO.inspect(twilio_msg, label: "twilio_msg")

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
    # IO.inspect(Patients.get_user(user_id), label: "apply_action :alerts")
    socket
    # -applies to index page behind the alert panel
    # - sent as prop through html to panel_component
    |> assign(:user, Patients.get_user(user_id))
  end
  # :new - adding a new user from scratch
  # user is blank map - assign user in upsert update
  defp apply_action(socket, :new, _params) do
    # IO.inspect(params, label: "apply_action :new")
    socket
    |> assign(:page_title, "Add New User")
    |> assign(:user, %{})
  end
  # MAYBE REMOVE :insert
  # :insert - adding a new user that already exists in DB
  # user is formed struct
  defp apply_action(socket, :insert, %{"user_id" => user_id} = _params) do
    # IO.inspect(user_id, label: "apply_action :insert1")
    socket
    |> assign(:page_title, "Insert Saved User")
    |> assign(:user, Patients.get_user(user_id))
  end
  # :insert - going back from display form
  # called when clicked on an existing user and redirecting
  defp apply_action(socket, :insert, %{"user_changeset" => %Ecto.Changeset{} = user_changeset}) do
    IO.inspect(user_changeset, label: "apply_action :insert changeset2XXXX")
    socket
    |> assign(:page_title, "Insert Existing User")
    |> assign(:user_changeset, user_changeset)
  end
  # :insert - if opened out of sequence with no params; like if route called directly
  defp apply_action(socket, :insert, _params) do
    # IO.inspect(params, label: "apply_action :insert out of sequence")
    socket
    |> assign(:page_title, "Insert Saved User")
  end
  # :index - rendering index page
  defp apply_action(socket, :index, _params) do
    # IO.inspect(socket.assigns, label: "apply_action :index")
    socket
      # delete garage data from hanging around
    |> maybe_delete_key(:user_changeset)
    |> maybe_delete_key(:existing_users_found)
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end
  # :search - rendering search page
  defp apply_action(socket, :search, _params) do
    # IO.inspect(params, label: "apply_action :search")
    socket
    |> assign(:page_title, "Search for User")
    |> assign(:user, nil)
  end
  # :display_existing_users - render display page
  defp apply_action(socket, :display_existing_users, %{"search_field_name" => search_field_name, "search_field_value" => search_field_value}) do
    # IO.inspect(params, label: "apply_action :display_existing_users")
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
  # :select - back from new when users found
  # when user is clicked on
  defp apply_action(socket, :select, %{"user_id" => user_id}) do
    user = Patients.get_user(user_id)
    changeset = Patients.change_user(user, %{})
    IO.inspect(changeset, label: "apply_action :select")
    socket
    |> assign(:page_title, "Activate Exisiting User?")
    |> assign(:user_changeset, changeset)
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

  # edit from show - main edit current function
  # called in upsert
  def save_user(socket, :edit, user_params) do
    case Patients.update_user(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket =
          socket
          |> put_flash(:error, "User not created")

        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  # back from :display - on :search when existing users found
  # called in upsert
  def save_user(socket, :insert, user_params) do
    # IO.inspect(socket.assigns, label: "save_user :insert")
    current_employee = socket.assigns[:current_employee]
    # user changeset is passed back from :display, should exist in assigns
    changeset1 = Map.get(socket.assigns, :changeset) || Patients.change_user(user_params)
    # construct user struct
    user_struct = apply_changes(changeset1)
    # IO.inspect(user_struct, label: "user_struct :insert")
    # build new changeset: this time with a unique constraint on health_card_num; form validation
    changeset2 = Patients.change_user(user_struct, %{})
    # IO.inspect(changeset2, label: "save_user :insert2")
    organization =
      TurnStile.Company.get_organization(current_employee.current_organization_login_id)

    case Patients.build_user_changeset_w_assocs(changeset2, current_employee, organization) do
      %Ecto.Changeset{} = user_changeset ->
        # IO.inspect(user_changeset, label: "save_user :insert3")
        # send msg data to parent & redirect
        case Patients.insert_user_changeset(user_changeset) do
          {:ok, _user} ->
            {:noreply,
             socket
             |> put_flash(:info, "User created successfully")
             |> push_redirect(to: socket.assigns.return_to)}

          # failures here are due to contraints
          {:error, %Ecto.Changeset{} = changeset} ->
            socket =
              socket
              |> put_flash(:error, "Unable to create this user. See error messages below.")

            {:noreply, assign(socket, :changeset, changeset)}
        end

      # error occured in  build_user_changeset_w_assocs
      _ ->
        socket =
          socket
          |> put_flash(:error, "User not created: An error occured during creation")

        {:noreply, socket}
    end
  end

  # add new user from index page
  # called in upsert
  def save_user(socket, :new, user_params) do
    current_employee = socket.assigns[:current_employee]

    # IO.inspect(current_employee, label: "user_params: save_user")

    # check employee has organization role
    case TurnStile.Staff.check_employee_matches_organization(current_employee) do
      {:error, error} ->
        IO.puts("ERROR: #{error}")
        {:error, error}

      {:ok, _} ->
        # IO.puts("Employee matches_organization")
        # check employee has permissions
        case EmployeeAuth.has_user_add_permissions?(socket, current_employee) do
          true ->
            # IO.puts("Employee has correct permissions")
            organization =
              TurnStile.Company.get_organization(current_employee.current_organization_login_id)

            changeset = Patients.create_user(user_params)

            case Patients.build_user_changeset_w_assocs(changeset, current_employee, organization) do
              %Ecto.Changeset{} = user_changeset ->
                # send msg data to parent & redirect
                if send_existing_users_update?(user_changeset, socket) do
                  {:noreply, socket}
                else
                  case Patients.insert_user_changeset(user_changeset) do
                    {:ok, _user} ->
                      {:noreply,
                       socket
                       |> put_flash(:info, "User created successfully")
                       |> push_redirect(to: socket.assigns.return_to)}

                    {:error, %Ecto.Changeset{} = changeset} ->
                      socket =
                        socket
                        |> put_flash(:error, "User not created")

                      {:noreply, assign(socket, :changeset, changeset)}
                  end
                end

              # build_user_changeset_w_assocs not a User
              _ ->
                socket =
                  socket
                  |> put_flash(:error, "User not created: An error occured during creation")

                {:noreply, socket}
            end

          # has_user_add_permissions not true
          false ->
            IO.puts("Employee does not have correct permissions")

            socket =
              socket
              |> put_flash(:error, "Insuffient employee permissions to perform user add")

            {:noreply, socket}
        end
    end
  end

  defp send_existing_users_update?(user_changeset, socket) do
    case handle_existing_users_send_data(user_changeset, socket) do
      {:ok} ->
        true

      _ ->
        false
    end
  end

  defp handle_existing_users_send_data(user_changeset, socket) do
    current_employee = socket.assigns[:current_employee]
    user_struct = apply_changes(user_changeset)

    {search_field_name, search_field_value, existing_users} =
      lookup_user_direct(
        user_struct,
        length(@user_search_fields) - 1,
        (current_employee && current_employee.current_organization_login_id) || 0
      )

    # IO.inspect(existing_users , label: "existing_users")
    if length(existing_users) > 0 do
      send(
        self(),
        {:users_found,
         %{
           existing_users_found: existing_users,
           user_changeset: user_changeset,
           redirect_to:
             Routes.user_index_path(
               socket,
               :display_existing_users,
               current_employee.current_organization_login_id,
               current_employee.id,
               search_field_name: search_field_name,
               search_field_value: search_field_value
             )
         }}
      )

      {:ok}
    else
      nil
    end
  end
  @doc """
  handle_generate_verification_code
  - generates a 6 digit alphanumeric code to give to user
  - inserts into DB so user can be verified
  """
  def handle_generate_verification_code(socket) do
     # generate a code
     code = UserToken.generate_user_verification_code(3)
    #  hash and insert into DB
     case Patients.build_and_insert_user_verification_code_token(code) do
      {user_url, _token, encoded_token} ->
        IO.inspect(user_url)
        IO.inspect(encoded_token)
        # optional pass user url here, maybe generate QR codes
        {:ok,
        socket
        |> maybe_assign_code(%{"code" => code})}
      {:error, error} ->
        {:error, error}
     end
  end

  def lookup_user_direct(_user_struct, nil, _organization_id), do: {nil, nil, []}
  def lookup_user_direct(_user_struct, 0, _organization_id), do: {nil, nil, []}

  def lookup_user_direct(user_struct, list_index, organization_id) do
    # search_fields are keys on user struct
    search_field_name = Enum.at(@user_search_fields, list_index)
    # IO.inspect(list_index, label: "list_index")
    # IO.inspect(search_field, label: "search_field")
    cond do
      # check if user has the key
      Map.get(user_struct, search_field_name) ->
        users =
          handle_get_users_by_field(
            search_field_name,
            Map.get(user_struct, search_field_name),
            organization_id
          )

        # IO.inspect(users, label: "USERS")
        if users === [] do
          # call recursively
          lookup_user_direct(user_struct, list_index - 1,organization_id )
        else
          # TODO: send field found by to display
          IO.puts("User(s) exist. Found by #{search_field_name}")
          search_field_value = Map.get(user_struct, search_field_name)
          {search_field_name, search_field_value, users}
        end

      true ->
        {:error, "Invalid search_field_name"}
    end
  end
  defp handle_get_users_by_field(field, field_value, organization_id) do
    case Patients.get_users_by_field(field, field_value, organization_id) do
      [] = _users ->
        # IO.puts("empty")
        []

      users ->
        # users
        # IO.inspect(users)
        users
    end
  end
  defp maybe_assign_code(_socket, nil), do: nil
  defp maybe_assign_code(socket, %{"code" => code}) do
    socket
    |> assign(:code, code)
  end
  def extract_message_popup_index(message) do
    if !is_nil(message) do
      # get key from message; is an int
      key_single_list = Map.keys(message)
      # saftey check to avoid error
      if length(key_single_list) === 1 do
        # returns key as int
        {:ok, key} = Enum.fetch(key_single_list, 0)
        key
      else
        IO.puts("Error: extract_message_popup_index - message is not a single key value pair")
        # TODO: think of better soluton
        9999
      end
    end
  end
  def extract_message_popup_user_params(nil), do: nil
  def extract_message_popup_user_params(message) do
      # get values side of map - is a list
      values = Map.values(message)
      # make sure list is 1 item
      if length(values) === 1 do
        # extact single item from list
        {:ok, value} = Enum.fetch(values, 0)
        # confirm single item is a map
        if is_map(value) do
          value
        else
          IO.puts("Error: extract_message_popup_user_params - message is not a single key value pair")
          "User Name Not Found"
        end
      else
        IO.puts("Error: extract_message_popup_user_params - message is not a single key value pair")
        nil
      end
  end
end
