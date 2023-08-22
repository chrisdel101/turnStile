defmodule TurnStile.Utils do
  # drop all values in list before index
  # IN: list - list to check
  # IN: to_match - item to match
  # OUT: list w single item
  def display_single_item_list(list_to_check, to_match) do
    # return index of item
    item = Enum.find(list_to_check, fn x -> x == to_match end)

    if item do
      [item]
    else
      raise ArgumentError, message: "Error in display_only. Index not found"
    end
  end

  # drop all values in list before index
  # IN: list of atoms - to check
  # IN: role - string
  # OUT: index of item
  def display_forward_list_values(list_to_check, role_str) do
    # return index of :atom item in list
    index = Enum.find_index(list_to_check, &(&1 == String.to_atom(role_str)))

    if index do
      Enum.drop(list_to_check, index)
    else
      raise ArgumentError, message: "Error in display_forward_list_values. Index not found"
    end
  end

# convert a list to a string with parenthese "()" - used for DB enum type syntax - https://stackoverflow.com/a/37216214/5972531
  def convert_to_parens_string(roles_list) do
    x =
      Enum.with_index(roles_list)
    |> Enum.map(fn x ->
      value = elem(x, 0)
      index = elem(x, 1)

      cond do
        index == 0 ->
          "('#{value}'"

        index == length(roles_list) - 1 ->
          "'#{value}')"

        true ->
          "'#{value}'"
      end
    end)
    |> Enum.join(", ")

    IO.puts("#{x}")
    x
  end

  def is_digit(str) do
    case Integer.parse(str) do
      {_, ""} -> true
      _ -> false
    end
  end

  # TODO - add env guards
  def convert_to_int(value) do
    if !is_nil(value) do
      case value do
        integer when is_integer(integer) ->
          integer

        float when is_float(float) ->
          round(float)

        string when is_binary(string) ->
          case String.to_integer(string) do
            integer when is_integer(integer) -> integer
          end

        _ ->
          0
        end
      else
        nil
    end
  end

  def read_json(json_file) do
    json_file
    |> File.read!()
    |> Jason.decode!()
  end

  def fetch_timezones_enum do
    query_result =
      Ecto.Adapters.SQL.query(TurnStile.Repo, "select enum_range(null::timezone)", [])

    case query_result do
      {:ok, %Postgrex.Result{rows: [rows]}} ->
        rows

      {:ok, %Postgrex.Result{rows: []}} ->
        []

      {:error, _} ->
        []
    end
  end

  def fetch_timezones do
    Tzdata.zone_list()
  end

  def shift_naive_datetime(naive_UTC, timezone_to_shift) do
    first_datetime = DateTime.from_naive!(naive_UTC, "Etc/UTC")

    case DateTime.shift_zone(first_datetime, timezone_to_shift) do
      {:ok, new_datetime} ->
        {:ok, new_datetime}

      {:error, error} ->
        {:error, error}
    end
  end

  def convert_to_readable_datetime(datetime, opts \\ [])

  def convert_to_readable_datetime(%DateTime{} = d, _opts) do
    "#{d.year}-#{d.month}-#{d.day} #{d.hour}:#{d.minute}:#{d.second}"
  end
  # i.e convert_to_readable_datetime(user.updated_at, timezone: user.employee.timezone)
  def convert_to_readable_datetime(%NaiveDateTime{} = d, opts) do
    if Keyword.get(opts, :timezone) do
      timezone = Keyword.get(opts, :timezone)
      {:ok, d} = shift_naive_datetime(d, timezone)
      "#{d.year}-#{d.month}-#{d.day} #{d.hour}:#{d.minute}:#{d.second}"
    else
      "#{d.year}-#{d.month}-#{d.day} #{d.hour}:#{d.minute}:#{d.second}"
    end
  end

  def filter_maps_list_by_truthy(list, search_term_str) do
    Enum.filter(list, fn map ->
      if !!Map.get(map, search_term_str) || !!Map.get(map, String.to_atom(search_term_str)),
        do: map,
        else: nil
    end)
  end

  # - checks if maps list have a value that matches
  def filter_maps_list_by_value(list, key, value) do
    Enum.filter(list, fn map ->
      if !!Map.get(map, key) && Map.get(map, key) === value,
        do: map,
        else: nil
    end)
  end

  def convert_arrow_map_to_atom(arrow_map) do
    Enum.map(arrow_map, fn {key, value} -> {String.to_atom(key), value} end) |> Map.new()

    # reduce way- Enum.reduce(%{}, fn {key, value}, acc -> Map.put(acc, String.to_atom(key), value) end)
  end

  def convert_atom_map_to_arrow(atom_map) do
    atom_map |> Enum.into(%{}, fn {key, value} -> {Atom.to_string(key), value} end)
    # reduce way
    # arrow_map =
    #   atom_map
    #   |> Enum.reduce(%{}, fn {key, value}, acc ->
    #     Map.put(acc, Atom.to_string(key), value)
    #   end)
  end

  def is_arrow_map?(map) do
    first_key = Map.keys(map) |> hd
   cond do
    is_binary(first_key) -> true
    is_atom(first_key) -> false
      true ->
        raise ArgumentError, message: "Error in is_arrow_map?. invalid map type"
    end
  end

  def remove_first_string_char(string, to_remove) do
    if !is_nil(string) && String.starts_with?(string, to_remove) do
      # Remove first character
      String.slice(string, 1..-1)
    else
      string
    end
  end

  def build_user_alert_url(user, encoded_user_token) do
    base_url = TurnStileWeb.Endpoint.url()
      confirmation_url = "#{base_url}/users/#{user.id}/#{encoded_user_token}"
      # Further processing
      confirmation_url
  end
  def build_user_registration_url(encoded_user_token) do
    base_url = TurnStileWeb.Endpoint.url()
      confirmation_url = "#{base_url}//users/register/#{encoded_user_token}"
      # Further processing
      confirmation_url
  end

  # check if user cookie exists; return user or nil; UNUSED
  def _check_if_user_cookie(cookies_map) do
    Enum.reduce_while(cookies_map, nil, fn {key, encoded_value}, _acc ->
      IO.puts("KEY: #{key}, VALUE: #{encoded_value}")
      # if cookie matching pattern
      if String.contains?(key, "turnStile-user") do
        # IO.puts("KEY: #{key}, VALUE: #{encoded_value}")
        # decode string to byte
        {:ok, decoded_bytes_token} = Base.decode64(encoded_value)
        # get cookie token and query DB
        user = TurnStile.Patients.get_user_by_session_token(decoded_bytes_token)
        {:halt, {user, encoded_value}}
      else
        {:cont, nil}
      end
    end)
  end
end
