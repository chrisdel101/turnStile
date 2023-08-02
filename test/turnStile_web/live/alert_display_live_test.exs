defmodule TurnStileWeb.AlertPanelLiveTest do
  use TurnStileWeb.ConnCase

  import Phoenix.LiveViewTest
  import TurnStile.AlertsFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_alert_display(_) do
    alert_display = alert_display_fixture()
    %{alert_display: alert_display}
  end

  describe "Index" do
    setup [:create_alert_display]

    test "lists all alerts", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.alert_display_index_path(conn, :index))

      assert html =~ "Listing Alerts"
    end

    test "saves new alert_display", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.alert_display_index_path(conn, :index))

      assert index_live |> element("a", "New Alert display") |> render_click() =~
               "New Alert display"

      assert_patch(index_live, Routes.alert_display_index_path(conn, :new))

      assert index_live
             |> form("#alert_display-form", alert_display: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#alert_display-form", alert_display: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.alert_display_index_path(conn, :index))

      assert html =~ "Alert display created successfully"
    end

    test "updates alert_display in listing", %{conn: conn, alert_display: alert_display} do
      {:ok, index_live, _html} = live(conn, Routes.alert_display_index_path(conn, :index))

      assert index_live |> element("#alert_display-#{alert_display.id} a", "Edit") |> render_click() =~
               "Edit Alert display"

      assert_patch(index_live, Routes.alert_display_index_path(conn, :edit, alert_display))

      assert index_live
             |> form("#alert_display-form", alert_display: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#alert_display-form", alert_display: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.alert_display_index_path(conn, :index))

      assert html =~ "Alert display updated successfully"
    end

    test "deletes alert_display in listing", %{conn: conn, alert_display: alert_display} do
      {:ok, index_live, _html} = live(conn, Routes.alert_display_index_path(conn, :index))

      assert index_live |> element("#alert_display-#{alert_display.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#alert_display-#{alert_display.id}")
    end
  end

  describe "Show" do
    setup [:create_alert_display]

    test "displays alert_display", %{conn: conn, alert_display: alert_display} do
      {:ok, _show_live, html} = live(conn, Routes.alert_display_show_path(conn, :show, alert_display))

      assert html =~ "Show Alert display"
    end

    test "updates alert_display within modal", %{conn: conn, alert_display: alert_display} do
      {:ok, show_live, _html} = live(conn, Routes.alert_display_show_path(conn, :show, alert_display))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Alert display"

      assert_patch(show_live, Routes.alert_display_show_path(conn, :edit, alert_display))

      assert show_live
             |> form("#alert_display-form", alert_display: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#alert_display-form", alert_display: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.alert_display_show_path(conn, :show, alert_display))

      assert html =~ "Alert display updated successfully"
    end
  end
end
