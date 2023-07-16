# TODO - remove enum  where not enum
# - leaving for now since easier to search for RouteTypesMap than just RouteTypes
defmodule RouteTypesMap do
  @moduledoc """
  Route Types.
  Ggetters for route types
   - Types are used to determine what type of route is being accessing by a client.
  ex /admin or not-/admin
  """
  @route_types %{
    "ADMIN" => "admin",
    "NON-ADMIN" => "non-admin",
    "TEST" => "test"
  }
  def get_route_types do
    @route_types
  end

  def get_route_type_value(key) do
    Map.get(@route_types, key)
  end
end

defmodule EmployeeRolesMap do
  @moduledoc """
    Role values for permissio
    - Used to determine access level by value
  """
  @permission_role_values %{
    "OWNER" => 1,
    "DEVELOPER" => 2,
    "ADMIN" => 3,
    "EDITOR" => 4,
    "CONTRIBUTOR" => 5,
    "VIEWER" => 6,
      "" => 7
  }
  @permission_roles %{
    "OWNER" => "owner",
    "DEVELOPER" => "developer",
    "ADMIN" => "admin",
    "EDITOR" => "editor",
    "CONTRIBUTOR" => "contributor",
    "VIEWER" => "viewer",
    "" => "none"
  }
  def get_permission_role_values do
    @permission_role_values
  end

  def get_permission_roles do
    @permission_roles
  end

  @spec get_permission_role(any) :: any
  def get_permission_role(key) do
    Map.get(@permission_roles, key)
  end

  def get_permission_role_value(key) do
    Map.get(@permission_role_values, key)
  end
end

defmodule ClientTypesEnum do
  @moduledoc """
    Client types
    getters for client types
    - Types are used to determine what type of client is accessing the system.
    example: true admin, employee, user, guest
  """
  @client_types ["admin", "employee", "user", "guest"]
  def get_client_types do
    @client_types
  end

  def get_client_type_value(type) do
    Enum.find(@client_types, &(&1 == type))
  end
end

defmodule AlertCategoryTypesMap do
  @moduledoc """
    AlertTypesMap
  """
  @alerts %{
    "INITIAL" => "initial", #initital SMS
    "CUSTOM" => "custom", # initial by email, or other SMS
    "CONFIRMATION" => "confirmation",
    "CANCELLATION" => "cancellation",
    "SYSTEM_RESPONSE" => "system_response"
  }
  def get_alerts do
    @alerts
  end

  def get_alert(key) do
    Map.get(@alerts, key)
  end

  def get_alerts_enum do
    @alerts |> Map.values() |> Enum.map(fn value -> String.to_atom(value) end)
  end
end

defmodule AlertFormatTypesMap do
  @moduledoc """
   AlertFormatTypesMap
  """
  @alerts %{
    "EMAIL" => "email",
    "SMS" => "sms"
  }
  def get_alerts do
    @alerts
  end

  def get_alert(key) do
    Map.get(@alerts, key)
  end

  def get_alerts_enum do
    @alerts |> Map.values() |> Enum.map(fn value -> String.to_atom(value) end)
  end
end

defmodule UserAlertStatusTypesMap do
  @moduledoc """
   AlertFormatTypesMap
  """
  @statuses %{
    "UNALERTED" => "unalerted",
    "PENDING" => "pending",
    "CONFIRMED" => "confirmed",
    "CANCELLED" => "cancelled",
    "EXPIRED" => "expired",
    "ERROR" => "error" # occurs only system failures; not invalid responses
  }
  def get_user_statuses do
    @statuses
  end

  def get_user_status(key) do
    Map.get(@statuses, key)
  end

  def get_user_statuses_enum do
    @statuses |> Map.values() |> Enum.map(fn value -> String.to_atom(value) end)
  end
end

defmodule PubSubTopicsMap do
  @topics %{
    "STATUS_UPDATE" => "status_update",
  }
  def get_topics do
    @topics
  end

  def get_topic(key) do
    Map.get(@topics, key)
  end

  def get_topics_enum do
    @topics |> Map.values() |> Enum.map(fn value -> String.to_atom(value) end)
  end
end
