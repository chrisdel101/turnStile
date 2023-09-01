defmodule TurnStileWeb.UserLive.Index do
  alias TurnStileWeb.AlertController
  use TurnStileWeb, :live_view

  alias TurnStile.Patients
  alias TurnStile.Staff
  alias TurnStile.Utils
  alias TurnStileWeb.EmployeeAuth
  alias TurnStileWeb.AlertUtils
  alias TurnStileWeb.UserLive.Index.IndexUtils
  alias TurnStileWeb.AlertUtils
  alias TurnStile.Alerts
  alias TurnStile.Alerts.Alert
  alias TurnStileWeb.UserLive.DisplayListComponent

  # live_actions [:new, :index, :alert, :edit]
  @interval 100000
  @filter_active_users_mins 30
  @wait_time_mins 60
  # @dialyzer {:nowarn_function, handle_event: 3}
  @dialyzer {:no_match, handle_event: 3}
  @non_idle_matching_users [
    %TurnStile.Patients.User{
      id: 13,
      email: "arssonist@yahoo.com",
      first_name: "Joe",
      health_card_num: 99_991_122,
      last_name: "Schmoe69",
      phone: "3065190138",
      date_of_birth: ~D[1900-01-01],
      is_active?: true,
      user_alert_status: "pending",
      alert_format_set: "email",
      employee_id: 1,
      organization_id: 1,
      confirmed_at: nil,
      activated_at: ~N[2023-08-28 00:39:25],
      deactivated_at: nil,
      inserted_at: ~N[2023-08-28 19:24:03],
      updated_at: ~N[2023-08-28 22:05:32]
    },
    %TurnStile.Patients.User{
      id: 1,
      email: "arssonist@yahoo.com",
      first_name: "Joe",
      health_card_num: 9999,
      last_name: "Schmoe",
      phone: "3065190138",
      date_of_birth: ~D[1900-01-01],
      is_active?: true,
      user_alert_status: "pending",
      alert_format_set: "email",
      employee_id: 1,
      organization_id: 1,
      confirmed_at: nil,
      activated_at: ~N[2023-08-25 18:42:02],
      deactivated_at: nil,
      inserted_at: ~N[2023-08-25 18:43:45],
      updated_at: ~N[2023-08-28 17:40:21]
    }
  ]
  @user_registatrion_messages [
    %{
      first_name: "Joe",
      last_name: "Schmoe",
      phone: "3065190138",
      email: "arssonist@yahoo.com",
      alert_format_set: "email",
      health_card_num: 9999,
      date_of_birth: Date.from_iso8601!("1900-01-01")
    },
    %{
      first_name: "Joe",
      last_name: "Schmoe2",
      phone: "3065190139",
      email: "blah@yahoo.com",
      alert_format_set: "email",
      health_card_num: 1234,
      date_of_birth: Date.from_iso8601!("1900-01-01")
    }
  ]
  @impl true
  def mount(_params, session, socket) do
    # TODO - cannot be null
    # get token from session
    employee_token = session["employee_token"]
    # use to get logged in user
    current_employee = Staff.get_employee_by_session_token(employee_token)
    organization_id = current_employee && current_employee.current_organization_login_id
    # on interval call :update func below
    if connected?(socket) do
      Process.send_after(self(), :update, @interval)
      # subscribe - broadcast is in alert controller
      # - delegates to handle_info funcs when called w params
      Phoenix.PubSub.subscribe(TurnStile.PubSub, PubSubTopicsMap.get_topic("STATUS_UPDATE")) # goes to :update
      Phoenix.PubSub.subscribe(TurnStile.PubSub, PubSubTopicsMap.get_topic("USER_REGISTRATION")) # goes to :handle_info
      Phoenix.PubSub.subscribe(TurnStile.PubSub, PubSubTopicsMap.get_topic("SEND_SMS_SYSTEM_RESPONSE")) # goes to :handle_info
      Phoenix.PubSub.subscribe(TurnStile.PubSub, PubSubTopicsMap.get_topic("MULTI_USER_TWILIO_MATCH")) # goes to :handle_info

    end
    main_index_users_list = Patients.filter_active_users_x_mins_past_last_update(organization_id, @filter_active_users_mins)
    # IO.inspect(socket.assigns, label: "INDEX: socket.assigns")
    socket =  IndexUtils.maybe_assign_code(socket, nil)
    {:ok,
     assign(
       socket,
       unmatched_SMS_users: [],
       user_registration_messages: [],
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
  # mutli user match recieived from twilio
  # comes from alert controller via PUBSUB
  # non_idle_matching_users is a list of active user with active state
  def handle_info(%{mutli_match_twilio_users: users_match_phone_list}, socket) do
    # users match org_id, is_active?, and active state
    matched_users_tuples = match_users_to_organization(users_match_phone_list, socket)
    # combine w default empty list
    unmtached_users = Enum.concat(socket.assigns.unmatched_SMS_users, matched_users_tuples)
    # IO.inspect(unmtached_users, label: "PUBSUB: indexed_tuples LIST in handle_info")
    {:noreply,
    socket
    |> assign(:unmatched_SMS_users, unmtached_users)
     |> assign(
       :popup_hero_title,
       "Multi-User Match - Employee Attention Required ."
     )
     |> assign(
       :popup_hero_body,
       "Incoming user response matches  multiple users accounts in your organizaion. Review to reconcile the issue."
     )}
  end

  # receives pubsub subscription from user self registation form
  # TODO: maybe optimize https://hexdocs.pm/phoenix_live_view/dom-patching.html#temporary-assigns
  def handle_info({:user_registation_form, %{user_params: user_params}}, socket) do
    # adding msgs one at a time, starting with empty list
    index = length(socket.assigns.user_registration_messages)
    # use list length before add to get index
    currrent_message = %{index => user_params}
    # add incoming message to storage
    messages = Enum.concat(socket.assigns.user_registration_messages, [currrent_message])
    # msg are formed like %{"0" => %{...}}

    {:noreply,
     socket
     |> assign(:user_registration_messages, messages)
     |> assign(:popup_message_title, "User Registration Form Recieved")
     |> assign(
       :popup_message_body,
       "The following user registration form was recieved. Please review and accept the user to register them."
     )}
  end
  def handle_info(%{send_response_params: %{
    twilio_params: twilio_params,
    conn: conn
  }}, socket) do
    IO.inspect(twilio_params, label: "PUBSUB: message in handle_info")
    AlertController.send_computed_SMS_system_response(conn, twilio_params)


    {:noreply, socket}
  end
  def handle_info(%{user_alert_status: _user_alert_status}, socket) do
    # IO.inspect(user_alert_status, label: "PUBSUB: message in handle_info")

    users =
      Patients.filter_active_users_x_mins_past_last_update(
        socket.assigns.current_employee.current_organization_login_id,
        @filter_active_users_mins
      )

    {:noreply, assign(socket, :users, users)}
  end

  # comes via send :upsert from :new
  def handle_info(
        %{"existing_users" => existing_users, "user_changeset" => user_changeset},
        socket
      ) do
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
      Patients.filter_active_users_x_mins_past_last_update(
        socket.assigns.current_employee.current_organization_login_id,
        @filter_active_users_mins
      )

    # IO.inspect(users, label: "update info")
    {:noreply, assign(socket, :users, users)}
  end

  # called from :search; when search results are found
  def handle_info({:users_found, %{"existing_users_found" => existing_users_found}}, socket) do
    IO.puts(
      "index handle info: {:users_found, %{'existing_users_found' => existing_users_found}}"
    )

    # IO.inspect("UUUUUUUU", label: "message in handle_info")
    # call update to refresh state on :display
    send_update(DisplayListComponent, id: "display")
    {:noreply, assign(socket, :existing_users_found, existing_users_found)}
    # IO.inspect(socket.assigns.existing_users_found, label: "message in handle_info rAFTER")
  end

  # called from :new match is found
  # sending found users list to :display
  def handle_info(
        {:users_found,
         %{
           existing_users_found: existing_users_found,
           user_changeset: user_changeset,
           redirect_to: redirect_to
         }},
        socket
      ) do
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
  def handle_info(
        {:reject_existing_users, %{user_changeset: user_changeset, redirect_to: redirect_to}},
        socket
      ) do
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
  # called via live_patch in index.html; :alert gets assigned as action
  # called on index when no user_id present
  def handle_params(%{"panel" => panel} = params, _url, socket) do
    # IO.inspect(params, label: "action on index")
    # IO.inspect(socket.assigns, label: "action on index")
    socket = assign(socket, :panel, panel)
    # call apply_action :index
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # called on :display-existing-users;
  #  when users list found during :new action
  def handle_params(
        %{"search_field_name" => _search_field_name, "search_field_value" => _search_field_value} =
          params,
        _url,
        socket
      ) do
    # IO.inspect(params, label: "params on index YYYY")
    # IO.inspect(socket.assigns, label: "params on index YYYY")
    #  socket =
    #   socket
    #   |> assign(:search_field_name, search_field_name)
    # apply_action :search
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # called on :select: back from :display_existing_user
  def handle_params(
        %{
          "employee_id" => _employee_id,
          "organization_id" => _organization_id,
          "user_id" => user_id
        } = params,
        _url,
        socket
      ) do
    IO.inspect(user_id, label: "handle_params main index:back from display")
    # apply_action :select
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # called on :index - main index render
  # called on :search button click
  def handle_params(
        %{"employee_id" => _employee_id, "organization_id" => _organization_id} = params,
        _url,
        socket
      ) do
    if Map.get(socket.assigns, :user_changeset) do
      # back action from from display "Add Original User"
      # IO.inspect(socket.assigns, label: "handle_params main index: w changeset")
      # IO.inspect(socket.assigns.live_action, label: "handle_params main index: w changeset")
      {:noreply,
       apply_action(socket, socket.assigns.live_action, %{
         "user_changeset" => socket.assigns[:user_changeset]
       })}
    else
      # call on load
      if length(socket.assigns.unmatched_SMS_users) === 0 do
        IO.puts("CALL1")
        {_noreply, socket} =
          handle_info(%{mutli_match_twilio_users: @non_idle_matching_users}, socket)
        {:noreply, apply_action(socket, socket.assigns.live_action, params)}
        else
           IO.puts("CALL2")

          {:noreply, apply_action(socket, socket.assigns.live_action, params)}
      end



      # {:noreply, socket} =
      #   handle_info(
      #     {:user_registation_form, %{user_params: Enum.at(@user_registatrion_messages, 1)}},
      #     socket
      #   )

      # IO.inspect(params, label: "handle_params main index: no changeset")
      # all other calls
      # :display_existing_users on event user_alert_match_review
      # {:noreply, apply_action(socket, socket.assigns.live_action, params)}
    end
  end

  @impl true
  # called - from popup match review button on-click
  def handle_event("user_alert_match_review", %{"value" => ""}, socket) do
    {:noreply, socket |> push_patch(to: Routes.user_index_path(socket, :display_existing_users, socket.assigns.current_employee.current_organization_login_id, socket.assigns.current_employee.id))}
  end

  # called - from popup match review button on-click
  def handle_event("user_alert_match_reject", _unsigned_params, socket) do

    {:noreply, socket |> push_patch(to: Routes.user_index_path(socket, :display_existing_users, socket.assigns.current_employee.current_organization_login_id, socket.assigns.current_employee.id))}
  end

  # called - from popup review button on-click
  # - extract mesage from list and send to apply_action
  def handle_event("user_registration_data_accept", params, socket) do
    # get id from button value field
    message_id = params["value"]
    # match id to msg key id
    message =
      Enum.find(socket.assigns.user_registration_messages, fn msg ->
        (Map.keys(msg) === [message_id]) || (Map.keys(msg) === [String.to_integer(message_id)])
      end)

    # send msg to upsert form
    user_params = Map.values(message)
    {:ok, user_params} = Enum.fetch(user_params, 0)
    IO.inspect(message, label: "user_registration_accept")
    # build new user
    changeset = Patients.create_user(user_params)
    # IO.inspect(changeset, label: "user_registration_accept")
    # apply_action(socket, :insert, %{"user_changeset" => changeset})
    {:noreply,
     socket
     |> assign(:live_action, :insert)
     # apply_action :insert
     |> apply_action(:insert, %{"user_changeset" => changeset},
       subtitle:
         "Review user registration information. If correct, click 'Save' to add user to system.",
        page_title: "Add New User Via Incoming User Data")}
  end
  # called - from popup reject button on-click
  # - extract mesage from list and send to apply_action
  def handle_event("user_registration_data_reject", params, socket) do
    # get id from button value field
    message_id = params["value"]
    IO.inspect("fired")
    # find msg in list
    message =
      Enum.find(socket.assigns.user_registration_messages, fn msg ->
        (Map.keys(msg) === [message_id]) || (Map.keys(msg) === [String.to_integer(message_id)])
      end)
    # remove message from list - cannot rely on index so must locate full message first
    user_registration_messages =
      List.delete(socket.assigns.user_registration_messages, message)
    # get values from map -returns list
    # user_params = Map.values(message)
    # extract values from list - returns map of user_params
    # {:ok, user_params} = Enum.fetch(user_params, 0)
    # IO.inspect(message, label: "user_registration_accept")
    # build new user
    # changeset = Patients.create_user(user_params)
    # IO.inspect(changeset, label: "user_registration_accept")
    # apply_action(socket, :insert, %{"user_changeset" => changeset})
    {:noreply,
     socket
     |> assign(:user_registration_messages, user_registration_messages)}
     # apply_action :insert
    #  |> apply_action(:insert, %{"user_changeset" => changeset},
    #    subtitle:
    #      "Review user registration information. If correct, click 'Save' to add user to system.",
    #     page_title: "Add New User Via Incoming User Data")}
  end

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

                    # handle_updating_user_alert_send_status error
                    {:error, error} ->
                      IO.inspect(error, label: "email index alert error in handle_event")

                      {
                        :noreply,
                        socket
                        |> put_flash(:error, "Failure in alert send. #{error}")
                      }
                  end

                # system/mailgun SMS error
                {:error, error} ->
                  # delete saved alert due to send error
                  Alerts.delete_alert(alert)
                  # handle mailgun error format
                  IO.inspect(error, label: "SMS index alert error in handle_event")

                  case error do
                    {error_code, %{"message" => error_message}} ->
                      {
                        :noreply,
                        socket
                        |> put_flash(
                          :error,
                          "Failure in alert send. #{error_message}. Code: #{error_code}"
                        )
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

                # system SMS error
                {:error, error} ->
                  # delete saved alert due to send error
                  Alerts.delete_alert(alert)

                  {
                    :noreply,
                    socket
                    |> put_flash(:error, "Failure in alert send. #{error}")
                  }
              end
            end

          # authenticate_and_save_sent_alert error
          {:error, error} ->
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
         Patients.filter_active_users_x_mins_past_last_update(
           current_employee.current_organization_login_id,
           @filter_active_users_mins
         )
       )}
    else
      socket =
        socket
        |> put_flash(:error, "Insuffient permissions to perform user delete")

      {:noreply,
       assign(
         socket,
         :users,
         Patients.filter_active_users_x_mins_past_last_update(
           current_employee.current_organization_login_id,
           @filter_active_users_mins
         )
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
         Patients.filter_active_users_x_mins_past_last_update(
           current_employee.current_organization_login_id,
           @filter_active_users_mins
         )
       )}
    else
      socket =
        socket
        |> put_flash(:error, "Insuffient permissions to perform user remove")

      {:noreply,
       assign(
         socket,
         :users,
         Patients.filter_active_users_x_mins_past_last_update(
           current_employee.current_organization_login_id,
           @filter_active_users_mins
         )
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
  # :index - rendering index page
  defp apply_action(socket, :index, _params) do
    # IO.inspect(socket.assigns, label: "apply_action :index")
    socket
    # delete garage data from hanging around
    |> IndexUtils.maybe_delete_key(:user_changeset)
    |> IndexUtils.maybe_delete_key(:existing_users_found)
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
  defp apply_action(socket, :display_existing_users, %{
         "search_field_name" => search_field_name,
         "search_field_value" => search_field_value
       }) do

    # IO.inspect(Map.get(socket.assigns, :user_changeset), label: "apply_action on display")
    socket
    |> assign(:search_field_name, search_field_name)
    |> assign(:search_field_value, search_field_value)
    |> assign(
      :return_to,
      Routes.user_index_path(
        socket,
        :insert,
        socket.assigns.current_employee.current_organization_login_id,
        socket.assigns.current_employee.id
      )
    )
    |> assign(:page_title, "Matching Users Found")
    |> assign(:user_changeset, Map.get(socket.assigns, :user_changeset))
    |> assign(:users, socket.assigns.users)
    |> assign(:existing_users_found, Map.get(socket.assigns, :existing_users_found))
  end
    # :display_existing_users - from event user_alert_match_review
    defp apply_action(socket, :display_existing_users, _params) do
      # IO.inspect(params, label: "apply_action :display_existing_users2")
      # IO.inspect(socket.assigns.unmatched_SMS_users, label: "apply_action on display")
      socket
      |> assign(:display_instruction, "Review the users below and identify which user account this incoming alert belongs to.")
      |> assign(:display_message, "A single user replied to an alert but multiple accounts match this phone number.")
      |> assign(:page_title, "Confirm User Match")
      |> assign(:users, socket.assigns.users)
      |> assign(:existing_users_found, Map.get(socket.assigns, :unmatched_SMS_users))
     # IO.inspect(socket.assigns.unmatched_SMS_users, label: "apply_action on display")
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

  # MAYBE REMOVE :insert
  # :insert - adding a new user that already exists in DB
  # user is formed struct
  defp apply_action(socket, :insert, %{"user_id" => user_id} = _params) do
    # IO.inspect(user_id, label: "apply_action :insert1")
    socket
    |> assign(:page_title, "Insert Saved User")
    |> assign(:user, Patients.get_user(user_id))
  end

  # :insert - if opened out of sequence with no params; like if route called directly
  defp apply_action(socket, :insert, _params) do
    # IO.inspect(params, label: "apply_action :insert out of sequence")
    socket
    |> assign(:page_title, "Insert Saved User")
  end

  # :insert
  # called - going back from display form
  # - when clicked on an existing user and redirecting
  # called - from employee popup review
  # - send user info to form for review before submit
  defp apply_action(socket, :insert, %{"user_changeset" => %Ecto.Changeset{} = user_changeset},opts) do
    subtitle = Keyword.get(opts, :subtitle)
    page_title = Keyword.get(opts, :page_title)
    IO.inspect(subtitle, label: "apply_action :insert changeset2XXXX")
    socket
    |> assign(:page_title, page_title || "Insert Existing User")
    |> assign(:subtitle, subtitle || nil)
    |> assign(:user_changeset, user_changeset)
  end
  defp match_users_to_organization(users_list, socket) do
    # IO.inspect(indexed_tuples, label: "PUBSUB: indexed_tuples LIST in handle_info")
    current_employee = socket.assigns.current_employee
    organization_id = current_employee.current_organization_login_id
    # get users match current org
    users_match_org_list = Enum.filter(users_list, fn x -> x.organization_id === organization_id end)
    # get active matching users
    active_pending_users = Utils.filter_maps_list_by_truthy(users_match_org_list, "is_active?")
    # IO.inspect(users_match_org_list, label: "match_users_to_organization users_match_org_list")
     # check non-idle state
    f = &is_user_alert_status_idle?/1
    # loop over all users - reject user idle w states
    non_idle_users = Enum.reject(active_pending_users, f)
    # IO.inspect(non_idle_users, label: "non_idle_users")
    # make into list w index
    # indexed_tuples = Enum.with_index(non_idle_users)
    # IO.inspect(indexed_tuples, label: "PUBSUB: indexed_tuples LIST in handle_info")
    # users are formed like {%{...}, 0}
    non_idle_users
  end
  defp is_user_alert_status_idle?(user) do
    # check for both syntax types
    user_alert_status = Map.get(user, "user_alert_status")
 ||  Map.get(user, :user_alert_status)
    # check if it matches one of the invalid states
    user_alert_status in [
      UserAlertStatusTypesMap.get_user_status("UNALERTED"),
      UserAlertStatusTypesMap.get_user_status("CANCELLED"),
      UserAlertStatusTypesMap.get_user_status("EXPIRED")]
  end
end
