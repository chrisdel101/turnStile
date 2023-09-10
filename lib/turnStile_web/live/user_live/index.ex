defmodule TurnStileWeb.UserLive.Index do
  use TurnStileWeb, :live_view

  alias TurnStile.Patients
  alias TurnStile.Staff
  alias TurnStileWeb.EmployeeAuth
  alias TurnStileWeb.AlertUtils
  alias TurnStileWeb.UserLive.Index.IndexUtils
  alias TurnStileWeb.AlertUtils
  alias TurnStile.Alerts
  alias TurnStile.Alerts.Alert
  alias TurnStileWeb.UserLive.Index.HandleInfo

  # live_actions [:new, :index, :alert, :edit]
  @interval 100000
  @filter_active_users_mins 30
  @dialyzer {:no_match, handle_event: 3}

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
       return_to: Routes.user_index_path(socket, :index, organization_id, current_employee.id),
       stored_callback: nil,
       stored_conn: nil
     )}
  end

  @impl true
  def handle_info(params, socket) do
    case params do
      {:user_registation_form, %{user_params: _user_params, organization_id: _organization_id}} ->
        HandleInfo.handle_user_registation_form(params, socket)
      %{user_alert_status: _user_alert_status} ->
        HandleInfo.handle_user_alert_status(params, socket, filter_active_users_mins: @filter_active_users_mins)
      %{"existing_users" => _existing_users, "user_changeset" => _user_changeset} ->
        HandleInfo.handle_existing_users_from_upsert(params, socket)
      :update -> HandleInfo.handle_update(params, socket, filter_active_users_mins: @filter_active_users_mins,
      interval: @interval)
      {:users_found, %{"existing_users_found" => _existing_users_found}} ->
        HandleInfo.handle_users_found_from_search(params, socket)
      {:users_found, %{
        existing_users_found: _existing_users_found,
        user_changeset: _user_changeset,
        redirect_to: _redirect_to
      }} ->
        HandleInfo.handle_users_found_from_new(params, socket)
      {:reject_existing_users, %{user_changeset: _user_changeset, redirect_to: _redirect_to}} ->
        HandleInfo.handle_reject_existing_users(params, socket)
    end
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
      # if length(socket.assigns.unmatched_SMS_users) === 0 do
      #   IO.puts("CALL1")
      #   # IO.inspect(@non_idle_matching_user)
      #   {_noreply, socket} =
      #     handle_info(%{mutli_match_twilio_users: @non_idle_matching_users,
      #     callback_response: &IO.puts/1,
      #     conn: %{}}, socket)
      #     {:noreply, apply_action(socket, socket.assigns.live_action, params)}
      #   else
      #      IO.puts("CALL2")

      #     {:noreply, apply_action(socket, socket.assigns.live_action, params)}
      # end



      {:noreply, socket} =
        handle_info(
          {:user_registation_form, %{user_params: Enum.at(@user_registatrion_messages, 1), organization_id: 1}},
          socket
        )
      {:noreply, socket}
      # IO.inspect(params, label: "handle_params main index: no changeset")
      # all other calls
      # :display_existing_users on event user_alert_match_review
      # {:noreply, apply_action(socket, socket.assigns.live_action, params)}
    end
  end

  @impl true
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
    IO.inspect(socket.assigns.user_registration_messages, label: "ZZZ")
    message =
      Enum.find(socket.assigns.user_registration_messages, fn msg ->
        ((elem(msg, 0) === message_id) || (elem(msg,0) === String.to_integer(message_id)))
      end)
      # IO.inspect(message, label: "CCCC")
    # send msg to upsert form
    user_params = elem(message, 1)
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
        attrs = Alerts.build_alert_specfic_attrs(
          socket.assigns.user,
          AlertCategoryTypesMap.get_alert("INITIAL"),
          alert_format
        )
        changeset = Alerts.create_new_alert(%Alert{}, attrs)
        AlertUtils.handle_sending_alert("send_initial_alert",
       changeset, socket)
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
    |> assign(:display_type, DisplayListComponentTypesMap.get_type("FOUND_USERS_LIST"))
  end
    # :display_existing_users - from event user_alert_match_review
    defp apply_action(socket, :display_existing_users, _params) do
      # IO.inspect(params, label: "apply_action :display_existing_users2")
      # IO.inspect(socket.assigns.unmatched_SMS_users, label: "applyd_action on display")
      socket
      |> assign(:display_instruction, "There is no way to auto-reconcile this since issue. Messages cannot be sent or recieved by multiple users with indentical phone numbers. Review the users in the list. Deactivate any users that are not actually in user. Otherwise you will need to change at least one user phone, or revert  to using email alerts.")
      |> assign(:display_message, "Employee Attention Required: A user reply has matched the phone number on multiple active user. accounts.")
      |> assign(:page_title, "Mutli User Match Found")
      |> assign(:users, socket.assigns.users)
      |> assign(:existing_users_found, Map.get(socket.assigns, :unmatched_SMS_users))
      |> assign(:display_type, DisplayListComponentTypesMap.get_type("MATCHED_USERS_LIST"))

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
  # - apply_action has opts
  defp apply_action(socket, :insert, %{"user_changeset" => %Ecto.Changeset{} = user_changeset}, opts) do
    subtitle = Keyword.get(opts, :subtitle)
    page_title = Keyword.get(opts, :page_title)
    # IO.inspect(user_changeset, label: "apply_action :insert changeset2XXXX")
    socket
    |> assign(:page_title, page_title || "Insert Existing User")
    |> assign(:subtitle, subtitle || nil)
    |> assign(:user_changeset, user_changeset)
  end
end
