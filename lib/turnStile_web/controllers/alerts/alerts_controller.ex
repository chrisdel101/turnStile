defmodule TurnStileWeb.AlertController do
  use TurnStileWeb, :controller

  def send_alert(conn, _opts) do

  #   curl -X POST "https://api.twilio.com/2010-04-01/Accounts/TWILIO_ACCOUNT_SID/Messages.json" \
  # --data-urlencode "Body=Hello from Twilio" \
  # --data-urlencode "From="+14344258584" \
  # --data-urlencode "To="+13065190138" \
  # -u "TWILIO_ACCOUNT_SID:TWILIO_AUTH_TOKEN"


    response = HTTPoison.post "https://api.twilio.com/2010-04-01/Accounts/TWILIO_ACCOUNT_SID/Messages.json", "{\"body\": \"Hello from Twilio\",\"From\":\"+14344258584\",\"To\":\"+13065190138\"}", [{"Content-Type", "application/json"}, {"Authorization", "Basic TWILIO_ACCOUNT_SID:TWILIO_AUTH_TOKEN"}]

    IO.inspect(response)
    conn
  end

end
