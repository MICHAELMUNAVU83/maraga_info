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

  test "shows a text preview when a post has no cover image", %{conn: conn} do
    post =
      post_fixture(%{
        category: MaragaInfo.Content.Post.blog_category(),
        image_url: nil,
        body: "This is the full post body.",
        preview_text: "This text is extracted into the card preview for readers."
      })

    {:ok, view, _html} = live(conn, ~p"/blog")

    assert has_element?(view, ~s(a[aria-label="Read #{post.title}"]), "This text is extracted")
    refute has_element?(view, ~s(img[alt="#{post.title}"]))
  end

  test "shows the post title in the preview when a PDF-only post has no text", %{conn: conn} do
    post =
      post_fixture(%{
        category: MaragaInfo.Content.Post.blog_category(),
        image_url: nil,
        body: nil,
        seo_description: nil,
        sections: [%{image_urls: ["/uploads/policy-brief.pdf"]}]
      })

    {:ok, view, _html} = live(conn, ~p"/blog")

    assert has_element?(view, ~s(a[aria-label="Read #{post.title}"]), post.title)
  end
end
