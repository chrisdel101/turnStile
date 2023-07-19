defmodule TurnStile.Patients.UserToken do
  use Ecto.Schema
  import Ecto.Query
  alias TurnStile.Patients.UserToken

  @hash_algorithm :sha256
  @rand_size 32

  @confirm_validity_in_days 1
  @confirm_validity_in_hours 6

  schema "user_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :user, TurnStile.Patients.User

    timestamps(updated_at: false)
  end

  @doc """
  Builds a token and its hash to be delivered to the user's email.

  The non-hashed token is sent to the employee email while the
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

  The query returns the employee found by the token, if any.

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
  def verify_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        hours = hours_for_context(context)
        # IO.inspect(token)
        query =
          from token in token_and_context_query(hashed_token, context),
            join: user in assoc(token, :user),
            # where: token.inserted_at > ago(^hours  , "hour"),
            select: user

        {:ok, query}
      :error ->
        :error
    end
  end
  # def test do
  #   user = TurnStile.Patients.get_user(1)
  #   IO.inspect(user.inserted_at)

  #   query =
  #     from u in TurnStile.Patients.User,
  #       where: u.inserted_at > ago(@confirm_validity_in_hours, "hour"),
  #       select: u
  #       IO.inspect(query)
  #     TurnStile.Repo.all(query)
  # end
  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp hours_for_context("confirm"), do: @confirm_validity_in_hours
  defp days_for_context("reset_password"), do: @reset_password_validity_in_days

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any.

  This is used to validate requests to change the user
  email. It is different from `verify_email_token_query/2` precisely because
  `verify_email_token_query/2` validates the email has not changed, which is
  the starting point by this function.

  The given token is valid if it matches its hashed counterpart in the
  database and if it has not expired (after @confirm_validity_in_days).
  database and if it has not expired (after @confirm_validity_in_hours).
  The context must always start with "change:".
  """
  def verify_change_email_token_query(encoded_token, "change:" <> _ = context) do
    case Base.url_decode64(encoded_token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(@confirm_validity_in_days, "day")

        {:ok, query}

      :error ->
        :error
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
      # IO.inspect(query, label: "Generated Query")
      query
    end
  end

  def user_and_contexts_query(user, [_ | _] = contexts) do
    if !is_nil(user) do
    from t in UserToken, where: t.user_id == ^user.id and t.context in ^contexts
    end
  end
end
