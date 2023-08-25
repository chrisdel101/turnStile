defmodule TurnStile.Patients.UserToken do
  use Ecto.Schema
  import Ecto.Query
  alias TurnStile.Patients.UserToken

  @hash_algorithm :sha256
  @rand_size 32

  # TOKEN LIFE SETTINGS for app
  @email_token_validity_hours 6
  # 6 hours for user session
  @session_token_validity_seconds 60 * 60 * 6
  # 5 mins for user signup token
  @verifcation_validity_mins 5
  # 30 mins before token is deleted
  @verifcation_expirtation_delete_mins 30

  def get_email_token_validity_hours, do: @email_token_validity_hours

  #  - contexts  - ["confirm", "reset_password", "verification"]
  def get_session_token_validity_seconds, do: @session_token_validity_seconds
  def verifcation_validity_mins, do: @session_token_validity_seconds
  def verifcation_expirtation_delete_mins, do: @verifcation_expirtation_delete_mins

  schema "user_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :user, TurnStile.Patients.User
    belongs_to :organization, TurnStile.Company.Organization

    timestamps(updated_at: false)
  end

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.

  The reason why we store session tokens in the database, even
  though Phoenix already provides a session cookie, is because
  Phoenix' default session cookies are not persisted, they are
  simply signed and potentially encrypted. This means they are
  valid indefinitely, unless you change the signing/encryption
  salt.

  Therefore, storing them allows individual user
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  You could then use this information to display all valid sessions
  and devices in the UI and allow users to explicitly expire any
  session they deem invalid.
  """
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %UserToken{token: token, context: "session", user_id: user.id}}
  end

  @doc """
  generate_user_verification_code
  - generate a code for user to access a form to register
  - is used to generate a DB code and URL
  """
  # use with 3 to get a six digit alphanumeric code
  def generate_user_verification_code(digits) do
    :crypto.strong_rand_bytes(digits) |> Base.encode16()
  end

  # generated and saved before user is crearted yet, so cannot contain any user info
  def build_verification_code_token(user_verification_code, organization_id) do
    build_hashed_verification_token(user_verification_code, organization_id)
  end

  defp build_hashed_verification_token(user_verification_code, organization_id) do
    # hash the code given to user
    hashed_token = :crypto.hash(@hash_algorithm, user_verification_code)
    # encode the original code and make into URL, store the hash in the DB
    {Base.url_encode64(user_verification_code, padding: false),
     %UserToken{
       token: hashed_token,
       context: "verification",
       organization_id: organization_id,
       sent_to: nil,
       user_id: nil
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any.

  The token is valid if it matches the value in the database
  """
  def verify_session_token_exists_query(token) do
    query =
      from token in token_and_context_query(token, "session"),
        join: user in assoc(token, :user),
        select: user

    {:ok, query}
  end

  def verify_session_token_valid_query(%Ecto.Query{} = query) do
    query =
      from user in query,
        where: user.inserted_at > ago(@session_token_validity_seconds, "second")

    {:ok, query}
  end

  @doc """
  Builds a token and its hash to be delivered to the user's email.

  The non-hashed token is sent to the user email while the
  hashed part is stored in the database. The original token cannot be reconstructed,
  which means anyone with read-only access to the database cannot directly use
  the token in the application to gain access. Furthermore, if the user changes
  their email in the system, the tokens sent to the previous email are no longer
  valid.

  Users can easily adapt the existing code to provide other types of delivery methods,
  for example, by phone numbers.
  - contexts  - ["confirm", "reset_password"]
  """
  def build_email_token(user, context) do
    build_hashed_token(user, context, user.email)
  end

  defp build_hashed_token(user, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)
    # IO.inspect(hashed_token, label: "tokenBH")
    # IO.inspect(Base.url_encode64(token, padding: false), label: "encoded_tokenBH")
    {Base.url_encode64(token, padding: false),
     %UserToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       user_id: user.id
     }}
  end
  @doc """
  verify_verification_token_exists_query
  - used to check that the token exists in the DB
  - returns the
  - error if input is invalid; decode 64 will not work with single digit
  """
  def verify_verification_token_exists_query(encoded_token, context \\ "verification") when is_binary(encoded_token) do
    case Base.url_decode64(encoded_token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in token_and_context_query(hashed_token, context),
            select: token

        {:ok, query}

      :error ->
        # no users matching token
        :invalid_input_token
    end
  end
  @doc """
  verify_verification_token_valid_query/2
  Two versions:
  -> V1 with encoded_token param 1
    - takes encoded token, decodes it, and finds if has matching hash in DB
    - when is_binary means "is string" in this case, not actual binary
  -> V2 with query param 1
  - same result as above but is piped a query- takes result of first query checking for existence
  - adds time limit via ago
  """
  def _verify_verification_token_valid_query(encoded_token, context) when is_binary(encoded_token) do
    case Base.url_decode64(encoded_token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        mins = verification_mins_for_context(context)

        query =
          from token in token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(^mins, "minute"),
            select: token

        {:ok, query}

      :error ->
        :invalid_input_token
    end
  end
  def verify_verification_token_valid_query(%Ecto.Query{} = query, _context) do
    query =
      from token in query,
        where: token.inserted_at > ago(@verifcation_validity_mins, "minute")

    {:ok, query}
  end

  @doc """
  verify_verification_token_expiry_peroid_query
  - takes a query that check for token and context exists
  - returns tokens past the expiry time
  """
  def _verify_verification_token_expiry_peroid_query(%Ecto.Query{} = query, _context) do
    query =
      from token in query,
        where: token.inserted_at < ago(@verifcation_expirtation_delete_mins, "minute")

    {:ok, query}
  end
  @doc """
  list_all_expired_verification_tokens_query
  - query for all V tokens past set time
  """
  def list_all_expired_verification_tokens_query do
    query =
      from token in UserToken,
        where: token.context == "verification" and token.inserted_at < ago(@verifcation_expirtation_delete_mins, "minute")
    {:ok, query}
  end

  @doc """
  encoded_verification_token_and_context_query
  - given the encoded token - returns the full veriifcation token struct;
  - used to fetch full token to compare, or delete
  """
  def encoded_verification_token_and_context_query(encoded_token, context) do
    case Base.url_decode64(encoded_token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in token_and_context_query(hashed_token, context),
            select: token

        {:ok, query}

      :error ->
        # invalid input token - no query made
        :invalid_input_token
    end
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any.

  The given token is valid if it matches its hashed counterpart in the
  database and the user email has not changed. This function also checks
  if the token is being used within a certain period, depending on the
  context. The default contexts supported by this function are either
  "confirm", for account confirmation emails, and "reset_password",
  for resetting the password. For verifying requests to change the email,
  see `verify_change_email_token_query/2`.
   # How ago works -
    # - sets `ago` time to current day minus x days
    # - for >, checks if compared comes after x days, and so is greater
    # - for <, checks if compared comes before x days, and so is less
    # - so if the > then it's actually past the ago time and is actually false, if < then it's before the ago time and is true
  """
  def verify_email_token_exists_query(encoded_token, context) do
    case Base.url_decode64(encoded_token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in token_and_context_query(hashed_token, context),
            join: user in assoc(token, :user),
            select: user

        {:ok, query}

      :error ->
        # no users matching token
        :invalid_input_token
    end
  end

  # takes an  token encoeded token using when to check
  def verify_email_token_valid_query(token, context) when is_binary(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        hours = email_hours_for_context(context)

        query =
          from token in token_and_context_query(hashed_token, context),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^hours, "hour"),
            select: user

        {:ok, query}

      :error ->
        :invalid_input_token
    end
  end

  # verify_email_token_valid_query
  # same result as above but is piped a query- takes result of first query adds time limit via ago
  def verify_email_token_valid_query(%Ecto.Query{} = query, _context) do
    query =
      from user in query,
        where: user.inserted_at > ago(@email_token_validity_hours, "hour")

    {:ok, query}
  end

  defp email_hours_for_context("confirm"), do: @email_token_validity_hours
  defp verification_mins_for_context("verification"), do: @verifcation_validity_mins

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any.

  This is used to validate requests to change the user
  email. It is different from `verify_email_token_query/2` precisely because
  `verify_email_token_query/2` validates the email has not changed, which is
  the starting point by this function.

  The given token is valid if it matches its hashed counterpart in the
  database and if it has not expired (after @confirm_validity_in_days).
  database and if it has not expired (after @email_token_validity_hours).
  The context must always start with "change:".
  """
  def verify_change_email_token_query(encoded_token, "change:" <> _ = context) do
    case Base.url_decode64(encoded_token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(@email_token_validity_hours, "day")

        {:ok, query}

      :error ->
        :error
    end
  end

  # returns full token from encoded email hash
  def encoded_email_token_and_context_query(encoded_token, context) do
    case Base.url_decode64(encoded_token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in token_and_context_query(hashed_token, context),
            join: user in assoc(token, :user),
            select: token

        {:ok, query}

      :error ->
        # invalid input token - no query made
        :invalid_input_token
    end
  end

  @doc """
  Returns the token struct for the given token value and context.
  """
  def token_and_context_query(token, context) do
    from UserToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given user for the given contexts.
  """
  def user_and_contexts_query(user, :all) do
    if !is_nil(user) && !is_nil(user.id) do
      query = from t in UserToken, where: t.user_id == ^user.id
      query
    end
  end

  def user_and_contexts_query(user, [_ | _] = contexts) do
    if !is_nil(user) do
      from t in UserToken, where: t.user_id == ^user.id and t.context in ^contexts
    end
  end

  def get_token(id) do
    TurnStile.Repo.get(UserToken, id)
  end

  def list_user_tokens(user_id) do
    query = from t in UserToken, where: t.user_id == ^user_id
    TurnStile.Repo.all(query)
  end
end
