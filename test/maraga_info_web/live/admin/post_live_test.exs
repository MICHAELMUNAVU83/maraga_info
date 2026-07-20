defmodule MaragaInfoWeb.Admin.PostLiveTest do
  use MaragaInfoWeb.ConnCase

  import Phoenix.LiveViewTest
  import MaragaInfo.ContentFixtures

  # The blog form pins the category (hidden input), so these attrs intentionally
  # omit `category` — it's supplied by the scope.
  @create_attrs %{
    title: "some title",
    seo_description: "some seo_description",
    preview_text: "Editable listing preview",
    status: "published",
    published_at: "2026-06-12T13:48:00Z",
    is_featured: true
  }
  @update_attrs %{
    title: "some updated title",
    seo_description: "some updated seo_description",
    status: "draft",
    published_at: "2026-06-13T13:48:00Z",
    is_featured: false
  }
  @invalid_attrs %{
    title: nil,
    seo_description: nil,
    status: "draft",
    is_featured: false
  }

  defp create_post(%{user: user}) do
    post = post_fixture(user, %{category: MaragaInfo.Content.Post.blog_category()})
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

      assert html =~ "All blog posts"
      assert html =~ post.title
    end

    test "saves new post", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/admin/blogs/new")

      assert new_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      upload_cover(new_live)

      positioned_attrs =
        Map.merge(@create_attrs, %{image_position_x: 32, image_position_y: 18})

      # The browser hook updates these hidden values after a drag, which causes
      # the form's normal validation event before submission.
      render_change(new_live, "validate", %{"post" => positioned_attrs})

      result =
        new_live
        |> form("#post-form", post: positioned_attrs)
        |> render_submit()

      assert {:ok, _show_live, html} = follow_redirect(result, conn)
      assert html =~ "Blog post created"
      assert html =~ "some title"

      post = Enum.find(MaragaInfo.Content.list_posts(), &(&1.title == "some title"))
      assert post.image_position_x == 32
      assert post.image_position_y == 18
      assert post.preview_text == "Editable listing preview"
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

  describe "Press releases" do
    setup [:register_and_log_in_user]

    test "stores cover uploads without image processing", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/admin/press-releases/new")

      new_live
      |> file_input("#post-form", :cover, [
        %{
          name: "press-cover.png",
          content: "copied without image processing",
          type: "image/png"
        }
      ])
      |> render_upload("press-cover.png")

      attrs = Map.put(@create_attrs, :title, "Press release with original cover")

      result =
        new_live
        |> form("#post-form", post: attrs)
        |> render_submit()

      assert {:ok, _show_live, html} = follow_redirect(result, conn)
      assert html =~ "press release created"

      post =
        Enum.find(
          MaragaInfo.Content.list_posts(),
          &(&1.title == "Press release with original cover")
        )

      upload_path = Path.join("priv/static", post.image_url)
      on_exit(fn -> File.rm(upload_path) end)

      assert File.read!(upload_path) == "copied without image processing"
    end
  end

  describe "Section attachments" do
    setup [:register_and_log_in_user]

    test "accepts PDF uploads for blog sections", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/admin/blogs/new")

      render_click(new_live, "add_section")
      render_click(new_live, "target_section", %{"index" => "0"})

      new_live
      |> file_input("#post-form", :section_images, [
        %{
          name: "campaign-brief.pdf",
          content: "%PDF-1.7 test document",
          type: "application/pdf"
        }
      ])
      |> render_upload("campaign-brief.pdf")

      html = render(new_live)
      assert html =~ "Open PDF"
      assert [_, upload_url] = Regex.run(~r/href="(\/uploads\/[^"]+\.pdf)"/, html)

      on_exit(fn -> File.rm(Path.join("priv/static", upload_url)) end)
    end

    test "offers preview generation for a previously saved PDF", %{conn: conn, user: user} do
      post =
        post_fixture(user, %{
          category: MaragaInfo.Content.Post.blog_category(),
          image_url: nil,
          preview_text: nil,
          sections: [%{image_urls: ["/uploads/existing-brief.pdf"]}]
        })

      {:ok, edit_live, _html} = live(conn, ~p"/admin/blogs/#{post}/edit")

      assert has_element?(
               edit_live,
               ~s(button[phx-click="generate_pdf_preview"]),
               "Generate preview from PDF"
             )

      assert render_click(edit_live, "generate_pdf_preview") =~
               "No text could be extracted"
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
