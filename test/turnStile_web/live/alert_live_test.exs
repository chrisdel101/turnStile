defmodule TurnStileWeb.AlertLiveTest do
  use TurnStileWeb.ConnCase

  import Phoenix.LiveViewTest
  import TurnStile.AlertsFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_alert(_) do
    alert = alert_fixture()
    %{alert: alert}
  end

  describe "Index" do
    setup [:create_alert]

    test "lists all alerts", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.alert_index_path(conn, :index))

      assert html =~ "Listing Alerts"
    end

    test "saves new alert", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.alert_index_path(conn, :index))

      assert index_live |> element("a", "New Alert") |> render_click() =~
               "New Alert"

      assert_patch(index_live, Routes.alert_index_path(conn, :new))

      assert index_live
             |> form("#alert-form", alert: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#alert-form", alert: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.alert_index_path(conn, :index))

      assert html =~ "Alert created successfully"
    end

    test "updates alert in listing", %{conn: conn, alert: alert} do
      {:ok, index_live, _html} = live(conn, Routes.alert_index_path(conn, :index))

      assert index_live |> element("#alert-#{alert.id} a", "Edit") |> render_click() =~
               "Edit Alert"

      assert_patch(index_live, Routes.alert_index_path(conn, :edit, alert))

      assert index_live
             |> form("#alert-form", alert: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#alert-form", alert: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.alert_index_path(conn, :index))

      assert html =~ "Alert updated successfully"
    end

    test "deletes alert in listing", %{conn: conn, alert: alert} do
      {:ok, index_live, _html} = live(conn, Routes.alert_index_path(conn, :index))

      assert index_live |> element("#alert-#{alert.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#alert-#{alert.id}")
    end
  end

  describe "Show" do
    setup [:create_alert]

    test "displays alert", %{conn: conn, alert: alert} do
      {:ok, _show_live, html} = live(conn, Routes.alert_show_path(conn, :show, alert))

      assert html =~ "Show Alert"
    end

    test "updates alert within modal", %{conn: conn, alert: alert} do
      {:ok, show_live, _html} = live(conn, Routes.alert_show_path(conn, :show, alert))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Alert"

      assert_patch(show_live, Routes.alert_show_path(conn, :edit, alert))

      assert show_live
             |> form("#alert-form", alert: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#alert-form", alert: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.alert_show_path(conn, :show, alert))

      assert html =~ "Alert updated successfully"
    end
  end
end
