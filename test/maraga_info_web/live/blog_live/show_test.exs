defmodule MaragaInfoWeb.BlogLive.ShowTest do
  use MaragaInfoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders the blog show page", %{conn: conn} do
    {:ok, _view, html} =
      live(conn, ~p"/blog/why-the-2017-election-ruling-still-defines-maraga")

    assert html =~ "A defining test of judicial independence"
    assert html =~ "Prev post"
    assert html =~ "Next post"
  end

  test "unknown slugs redirect to home", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/blog/missing-post")
  end
end
