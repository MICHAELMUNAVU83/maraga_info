defmodule MaragaInfoWeb.BlogLive.IndexTest do
  use MaragaInfoWeb.ConnCase, async: true

  import MaragaInfo.ContentFixtures
  import Phoenix.LiveViewTest

  test "uses the saved cover focal position without leaving gaps", %{conn: conn} do
    post =
      post_fixture(%{
        category: MaragaInfo.Content.Post.blog_category(),
        image_position_x: 35,
        image_position_y: 12
      })

    {:ok, view, _html} = live(conn, ~p"/blog")

    assert has_element?(
             view,
             ~s(img[src="#{post.image_url}"][style="object-position: 35% 12%"])
           )

    assert has_element?(view, ~s(img[src="#{post.image_url}"].object-cover))
  end
end
