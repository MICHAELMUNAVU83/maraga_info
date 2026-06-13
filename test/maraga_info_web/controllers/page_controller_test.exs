defmodule MaragaInfoWeb.PageControllerTest do
  use MaragaInfoWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "Independent news, background and analysis on David Maraga"
    assert response =~ "Nairobi National Park Protest – Maraga Arrested"
    assert response =~ ~s(rel="icon" href="/images/favicon.ico")
    assert response =~ ~s(<link rel="canonical" href="https://davidmaraga.info")
  end
end
