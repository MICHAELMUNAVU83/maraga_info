defmodule MaragaInfoWeb.BlogLive.ShowTest do
  use MaragaInfoWeb.ConnCase, async: true

  import MaragaInfo.ContentFixtures
  import Phoenix.LiveViewTest

  test "renders the blog show page", %{conn: conn} do
    post_fixture(%{
      title: "Newer post",
      slug: "newer-post",
      category: "News",
      excerpt: "A newer post.",
      seo_description: "A newer post.",
      image_url: "/images/maxresdefault.jpg",
      intro: "A newer intro.",
      body: "A newer story.",
      status: :published,
      published_at: ~U[2026-06-13 12:00:00Z]
    })

    post =
      post_fixture(%{
        title: "Why the 2017 election ruling still defines Maraga",
        slug: "why-the-2017-election-ruling-still-defines-maraga",
        category: "Analysis",
        excerpt: "The Supreme Court decision still defines his public legacy.",
        seo_description: "Analysis of the 2017 ruling.",
        image_url: "/images/maxresdefault.jpg",
        intro: "For many Kenyans, this ruling defines Maraga's legacy.",
        body: "A defining test of judicial independence.\n\nWhy the ruling still matters.",
        status: :published,
        published_at: ~U[2026-06-12 12:00:00Z]
      })

    post_fixture(%{
      title: "Older post",
      slug: "older-post",
      category: "Background",
      excerpt: "An older post.",
      seo_description: "An older post.",
      image_url: "/images/IMG_2052.jpg",
      intro: "An older intro.",
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
end
