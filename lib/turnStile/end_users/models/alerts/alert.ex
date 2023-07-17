defmodule TurnStile.Alerts.Alert do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  Alert Schema
  -alerts belong to one user
  -alerts belong to one employee
  -alerts belong to one organization
  """
    schema "alerts" do
      field(:title, :string)
      field(:body, :string)
      field(:to, :string)
      field(:from, :string)
      field(:alert_category, :string)
      field(:alert_format, :string)
      belongs_to(:employee, TurnStile.Staff.Employee)
      belongs_to(:user, TurnStile.Patients.User)
      belongs_to(:organization, TurnStile.Company.Organization)
      timestamps()

      # - when alert is recieved this is response sent back to sender; webhook response
      embeds_one :system_response, SystemResponse, on_replace: :update
      do
        field(:title, :string)
        field(:body, :string)
        field(:to, :string)
        field(:from, :string)
        field(:alert_format, :string)
        field(:alert_category, :string, default: AlertCategoryTypesMap.get_alert("SYSTEM_RESPONSE"))
      end
    end

  @doc false
  def changeset(alert, attrs, validate? \\ false) do
    alert
    |> cast(attrs, [:title, :body, :to, :from, :alert_category, :alert_format, :employee_id, :user_id])
    |> validate_when_required(validate?, [:title, :body, :to, :from])
    |> validate_category_for_response(attrs)
    |> maybe_cast_system_response(attrs)
  end

  def system_response_changeset(system_response, attrs \\ %{}) do
    system_response
    |> cast(attrs, [:title, :body, :to, :from, :alert_category, :alert_format])
    |> validate_required([:body, :to, :from, :alert_format])
  end

  defp validate_when_required(alert, validate?, attrs) do
    if validate? do
      alert
      |> validate_required(attrs)
    else
      alert
    end
  end

  # make sure system_resonse is only added when alert_category is CONFIRMATION or CANCELLATION;
  # returns plain changeset - no response yet
  defp validate_category_for_response(alert_changeset, attrs) do
    if has_system_response?(attrs) do

      # if category is on the changes
      cond do
        # check if catetory is in changeset
        Map.get(alert_changeset, :changes) && Map.get(alert_changeset.changes, :alert_category) ->
          if alert_changeset.changes.alert_category === AlertCategoryTypesMap.get_alert("CONFIRMATION") ||
               alert_changeset.alert_category === AlertCategoryTypesMap.get_alert("CANCELLATION") do
            # IO.inspect( alert_changeset, label: "XXX")
            alert_changeset
          else
            add_error(alert_changeset, :system_response, "Invalid alert category.")
          end
        # check if catetory is part of data
        Map.get(alert_changeset, :data) && Map.get(alert_changeset.data, :alert_category) ->
          if (alert_changeset.data.alert_category === AlertCategoryTypesMap.get_alert("CONFIRMATION") ||
          alert_changeset.data.alert_category === AlertCategoryTypesMap.get_alert("CANCELLATION")) do
            # IO.inspect( alert_changeset, label: "XXX")
            alert_changeset
          else
            add_error(alert_changeset, :system_response, "Invalid alert category.")
          end
        true ->
          add_error(alert_changeset, :system_response, "Missing alert category. Cannot verify.")
      end
    else
      alert_changeset
    end
  end
  # - add response map into changeset here
  defp maybe_cast_system_response(alert_changeset, attrs) do
    case has_system_response?(attrs) do
      true ->
        cast_embed(alert_changeset, :system_response, with: &system_response_changeset/2)

      false ->
        alert_changeset
    end
  end

  defp has_system_response?(attrs) do
    Map.has_key?(attrs, :system_response)
  end
end
