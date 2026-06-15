defmodule MaragaInfo.ContentTest do
  use MaragaInfo.DataCase

  alias MaragaInfo.Content

  describe "posts" do
    alias MaragaInfo.Content.Post

    import MaragaInfo.ContentFixtures

    @invalid_attrs %{
      title: nil,
      category: nil,
      body: nil,
      slug: nil,
      seo_description: nil,
      image_url: nil,
      status: nil,
      is_featured: nil
    }

    test "list_posts/0 returns all posts" do
      post = post_fixture()
      assert Content.list_posts() == [post]
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      assert Content.get_post!(post.id) == post
    end

    test "create_post/1 with valid data creates a post" do
      valid_attrs = %{
        title: "some title",
        category: "some category",
        body: "some body",
        slug: "some slug",
        seo_description: "some seo_description",
        image_url: "/images/maxresdefault.jpg",
        published_at: ~U[2026-06-12 13:48:00Z],
        status: :published,
        is_featured: true
      }

      assert {:ok, %Post{} = post} = Content.create_post(valid_attrs)
      assert post.title == "some title"
      assert post.category == "some category"
      assert post.body == "some body"
      assert post.slug == "some-slug"
      assert post.seo_description == "some seo_description"
      assert post.image_url == "/images/maxresdefault.jpg"
      assert post.published_at == ~U[2026-06-12 13:48:00Z]
      assert post.status == :published
      assert post.is_featured == true
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_post(@invalid_attrs)
    end

    test "update_post/2 with valid data updates the post" do
      post = post_fixture()

      update_attrs = %{
        title: "some updated title",
        category: "some updated category",
        body: "some updated body",
        slug: "some updated slug",
        seo_description: "some updated seo_description",
        image_url: "/images/IMG_2052.jpg",
        published_at: ~U[2026-06-13 13:48:00Z],
        status: :draft,
        is_featured: false
      }

      assert {:ok, %Post{} = post} = Content.update_post(post, update_attrs)
      assert post.title == "some updated title"
      assert post.category == "some updated category"
      assert post.body == "some updated body"
      assert post.slug == "some-updated-slug"
      assert post.seo_description == "some updated seo_description"
      assert post.image_url == "/images/IMG_2052.jpg"
      assert post.published_at == ~U[2026-06-13 13:48:00Z]
      assert post.status == :draft
      assert post.is_featured == false
    end

    test "update_post/2 with invalid data returns error changeset" do
      post = post_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_post(post, @invalid_attrs)
      assert post == Content.get_post!(post.id)
    end

    test "delete_post/1 deletes the post" do
      post = post_fixture()
      assert {:ok, %Post{}} = Content.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Content.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset" do
      post = post_fixture()
      assert %Ecto.Changeset{} = Content.change_post(post)
    end
  end
end
