defmodule MaragaInfoWeb.BlogLive.ShowTest do
  use MaragaInfoWeb.ConnCase, async: true

  import MaragaInfo.ContentFixtures
  import Phoenix.LiveViewTest

  test "renders the blog show page", %{conn: conn} do
    post_fixture(%{
      title: "Newer post",
      slug: "newer-post",
      category: "News",
      seo_description: "A newer post.",
      image_url: "/images/maxresdefault.jpg",
      body: "A newer story.",
      status: :published,
      published_at: ~U[2026-06-13 12:00:00Z]
    })

    post =
      post_fixture(%{
        title: "Why the 2017 election ruling still defines Maraga",
        slug: "why-the-2017-election-ruling-still-defines-maraga",
        category: "Analysis",
        seo_description: "Analysis of the 2017 ruling.",
        image_url: "/images/maxresdefault.jpg",
        body: "A defining test of judicial independence.\n\nWhy the ruling still matters.",
        status: :published,
        published_at: ~U[2026-06-12 12:00:00Z]
      })

    post_fixture(%{
      title: "Older post",
      slug: "older-post",
      category: "Background",
      seo_description: "An older post.",
      image_url: "/images/IMG_2052.jpg",
      body: "An older story.",
      status: :published,
      published_at: ~U[2026-06-11 12:00:00Z]
    })

    {:ok, _view, html} = live(conn, ~p"/blog/#{post.slug}")

    assert html =~ "A defining test of judicial independence"
    assert html =~ "Prev post"
    assert html =~ "Next post"
  end

  test "unknown slugs redirect to home", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/blog/missing-post")
  end

  test "renders a post without an image using the default SEO image", %{conn: conn} do
    post =
      post_fixture(%{
        title: "Post without an image",
        slug: "post-without-an-image",
        image_url: nil
      })

    {:ok, _view, html} = live(conn, ~p"/blog/#{post.slug}")

    assert html =~ "Post without an image"
    assert html =~ ~s("image":["https://davidmaraga.info/images/IMG_2052.jpg"])
  end

  test "renders sharing controls for a title-less press release", %{conn: conn} do
    post =
      post_fixture(%{
        title: nil,
        slug: "title-less-press-release",
        category: "Press Releases"
      })

    {:ok, _view, html} = live(conn, ~p"/blog/#{post.slug}")

    assert html =~ "Share this story"
    assert html =~ "David+Maraga+Info"
    assert html =~ ~s(data-url="https://davidmaraga.info/blog/title-less-press-release")
  end
end
