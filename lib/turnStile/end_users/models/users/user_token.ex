defmodule TurnStile.Patients.UserToken do
  use Ecto.Schema
  import Ecto.Query
  alias TurnStile.Patients.UserToken

  @hash_algorithm :sha256
  @rand_size 32

   # TOKEN LIFE SETTINGS for app
   @email_token_validity_hours 6
   @email_token_validity_seconds 1 # unused
   @session_token_validity_seconds 5000

   def get_email_token_validity_hours, do: @email_token_validity_hours

   def get_session_token_validity_seconds, do: @session_token_validity_seconds



  schema "user_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :user, TurnStile.Patients.User

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
    query = from user in query,
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
    IO.inspect(hashed_token, label: "tokenBH")
    IO.inspect(Base.url_encode64(token, padding: false), label: "encoded_tokenBH")
    {Base.url_encode64(token, padding: false),
     %UserToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       user_id: user.id
     }}
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
  # takes a token
  def verify_email_token_valid_query(token, context) when is_binary(token) do
        case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        hours = email_hours_for_context(context)
        query =
          from token in token_and_context_query(hashed_token, context),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(30  , "second"),
            select: user

        {:ok, query}
      :error ->
        :invalid_input_token
    end
  end
  # verify_email_token_valid_query
    # same result as above but is piped a query- takes result of first query adds time limit via ago
  def verify_email_token_valid_query(%Ecto.Query{} = query, _context) do
      query = from user in query,
      where: user.inserted_at > ago(@email_token_validity_hours, "hour")
      {:ok, query}
    end
  defp email_hours_for_context("confirm"), do: @email_token_validity_hours

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
  def encoded_token_and_context_query(encoded_token, context) do
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
