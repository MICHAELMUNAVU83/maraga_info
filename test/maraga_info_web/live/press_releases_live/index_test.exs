defmodule MaragaInfoWeb.PressReleasesLive.IndexTest do
  use MaragaInfoWeb.ConnCase, async: true

  import MaragaInfo.ContentFixtures
  import Phoenix.LiveViewTest

  test "renders a press release without an image block", %{conn: conn} do
    post =
      post_fixture(%{
        title: "Statement without a cover",
        category: MaragaInfo.Content.Post.press_release_category(),
        image_url: nil
      })

    {:ok, _view, html} = live(conn, ~p"/press-releases")

    assert html =~ "Statement without a cover"
    refute html =~ ~s(<img src="" alt="#{post.title}")
    refute html =~ ~s(alt="#{post.title}")
  end
end
