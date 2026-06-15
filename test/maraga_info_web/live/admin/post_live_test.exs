defmodule MaragaInfoWeb.Admin.PostLiveTest do
  use MaragaInfoWeb.ConnCase

  import Phoenix.LiveViewTest
  import MaragaInfo.ContentFixtures

  @create_attrs %{
    title: "some title",
    category: "some category",
    body: "some body",
    seo_description: "some seo_description",
    status: "published",
    published_at: "2026-06-12T13:48:00Z",
    is_featured: true
  }
  @update_attrs %{
    title: "some updated title",
    category: "some updated category",
    body: "some updated body",
    seo_description: "some updated seo_description",
    status: "draft",
    published_at: "2026-06-13T13:48:00Z",
    is_featured: false
  }
  @invalid_attrs %{
    title: nil,
    category: nil,
    body: nil,
    seo_description: nil,
    status: "draft",
    is_featured: false
  }

  defp create_post(%{user: user}) do
    post = post_fixture(user)
    %{post: post}
  end

  defp upload_cover(view) do
    view
    |> file_input("#post-form", :cover, [
      %{
        name: "cover.png",
        content: File.read!("priv/static/images/logo.png"),
        type: "image/png"
      }
    ])
    |> render_upload("cover.png")
  end

  describe "Dashboard" do
    setup [:register_and_log_in_user, :create_post]

    test "shows the admin overview", %{conn: conn, post: post} do
      {:ok, _dashboard_live, html} = live(conn, ~p"/admin")

      assert html =~ "Dashboard"
      assert html =~ "Recent posts"
      assert html =~ post.title
    end
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_post]

    test "lists all posts", %{conn: conn, post: post} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/blogs")

      assert html =~ "All posts"
      assert html =~ post.title
    end

    test "saves new post", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/admin/blogs/new")

      assert new_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      upload_cover(new_live)

      result =
        new_live
        |> form("#post-form", post: @create_attrs)
        |> render_submit()

      assert {:ok, _show_live, html} = follow_redirect(result, conn)
      assert html =~ "Blog post created"
      assert html =~ "some title"
    end

    test "updates post from the listing", %{conn: conn, post: post} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/blogs")

      assert {:ok, edit_live, _html} =
               index_live
               |> element("#posts-#{post.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/admin/blogs/#{post}/edit")

      assert edit_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      result =
        edit_live
        |> form("#post-form", post: @update_attrs)
        |> render_submit()

      assert {:ok, _show_live, html} = follow_redirect(result, conn)
      assert html =~ "Blog post updated"
      assert html =~ "some updated title"
    end

    test "deletes post in listing", %{conn: conn, post: post} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/blogs")

      assert index_live |> element("#posts-#{post.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#posts-#{post.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_post]

    test "displays post", %{conn: conn, post: post} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/blogs/#{post}")

      assert html =~ post.title
      assert html =~ "Details"
    end

    test "navigates to the editor", %{conn: conn, post: post} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/blogs/#{post}")

      assert {:ok, edit_live, _html} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/admin/blogs/#{post}/edit")

      result =
        edit_live
        |> form("#post-form", post: @update_attrs)
        |> render_submit()

      assert {:ok, _show_live, html} = follow_redirect(result, conn)
      assert html =~ "Blog post updated"
      assert html =~ "some updated title"
    end
  end
end
