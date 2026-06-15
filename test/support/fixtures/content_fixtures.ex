defmodule MaragaInfo.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MaragaInfo.Content` context.
  """

  alias MaragaInfo.Accounts.User

  @doc """
  Generate a post.
  """
  def post_fixture(), do: post_fixture(%{})
  def post_fixture(%User{} = user), do: post_fixture(user, %{})

  def post_fixture(attrs) do
    unique = System.unique_integer([:positive])

    {:ok, post} =
      attrs
      |> Enum.into(%{
        body: "some body\n\nsome follow-up paragraph",
        category: "some category",
        image_url: "/images/maxresdefault.jpg",
        is_featured: true,
        published_at: ~U[2026-06-12 13:48:00Z],
        status: :published,
        seo_description: "some seo_description",
        slug: "some-slug-#{unique}",
        title: "some title #{unique}"
      })
      |> MaragaInfo.Content.create_post()

    MaragaInfo.Content.get_post!(post.id)
  end

  def post_fixture(%User{} = user, attrs) do
    unique = System.unique_integer([:positive])

    attrs =
      Enum.into(attrs, %{
        body: "some body\n\nsome follow-up paragraph",
        category: "some category",
        image_url: "/images/maxresdefault.jpg",
        is_featured: true,
        published_at: ~U[2026-06-12 13:48:00Z],
        status: :published,
        seo_description: "some seo_description",
        slug: "some-slug-#{unique}",
        title: "some title #{unique}"
      })

    {:ok, post} = MaragaInfo.Content.create_post(user, attrs)
    MaragaInfo.Content.get_post!(post.id)
  end
end
