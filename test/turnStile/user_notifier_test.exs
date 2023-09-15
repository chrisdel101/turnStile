defmodule TurnStile.Patients.UserNotifierTest do
  use ExUnit.Case, async: true
  import Swoosh.TestAssertions

  alias TurnStile.Patients.UserNotifier

  test "deliver_initial/1" do
    user = %{name: "Alice", email: "alice@example.com"}

    UserNotifier.deliver_initial(user)

    assert_email_sent(
      subject: "Welcome to Phoenix, Alice!",
      to: {"Alice", "alice@example.com"},
      text_body: ~r/Hello, Alice/
    )
  end

  test "deliver_custom/1" do
    user = %{name: "Alice", email: "alice@example.com"}

    UserNotifier.deliver_custom(user)

    assert_email_sent(
      subject: "Welcome to Phoenix, Alice!",
      to: {"Alice", "alice@example.com"},
      text_body: ~r/Hello, Alice/
    )
  end
end
