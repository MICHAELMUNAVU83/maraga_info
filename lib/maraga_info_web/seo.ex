defmodule MaragaInfoWeb.Seo do
  @moduledoc false

  @site_name "David Maraga Info"
  @site_url "https://davidmaraga.info"
  @default_title "David Maraga News, Biography & Analysis"
  @default_description """
  Independent news, background and analysis on David Maraga, Kenya's former Chief Justice, \
  his judicial legacy and major public developments tied to his record.
  """
  @default_image "/images/IMG_2052.jpg"

  def site_name, do: @site_name
  def site_url, do: @site_url
  def default_title, do: @default_title
  def default_description, do: @default_description
  def default_image_url, do: absolute_url(@default_image)

  def absolute_url("http" <> _ = url), do: url
  def absolute_url("/" <> _ = path), do: @site_url <> path
  def absolute_url(path), do: @site_url <> "/" <> path

  def meta(assigns) do
    %{
      title: assigns[:page_title] || @default_title,
      description: assigns[:page_description] || @default_description,
      canonical_url: assigns[:canonical_url] || @site_url,
      image_url: absolute_url(assigns[:page_image] || @default_image),
      type: assigns[:page_type] || "website",
      robots: assigns[:page_robots] || "index,follow,max-image-preview:large",
      published_time: assigns[:page_published_time],
      modified_time: assigns[:page_modified_time] || assigns[:page_published_time],
      structured_data: List.wrap(assigns[:structured_data] || default_structured_data())
    }
  end

  def default_structured_data do
    [
      website_schema(),
      person_schema()
    ]
  end

  def home_structured_data(posts) do
    [
      website_schema(),
      person_schema(),
      %{
        "@context" => "https://schema.org",
        "@type" => "CollectionPage",
        "name" => @default_title,
        "url" => @site_url,
        "description" => @default_description,
        "mainEntity" => %{
          "@type" => "ItemList",
          "itemListElement" =>
            Enum.with_index(posts, 1)
            |> Enum.map(fn {post, index} ->
              %{
                "@type" => "ListItem",
                "position" => index,
                "url" => article_url(post.slug),
                "name" => post.title
              }
            end)
        }
      }
    ]
  end

  def article_structured_data(post) do
    [
      website_schema(),
      %{
        "@context" => "https://schema.org",
        "@type" => "NewsArticle",
        "headline" => post.title,
        "description" => post.seo_description,
        "datePublished" => post.iso_date,
        "dateModified" => post.iso_date,
        "image" => [absolute_url(post.image)],
        "mainEntityOfPage" => article_url(post.slug),
        "about" => person_schema(),
        "author" => publisher_schema(),
        "publisher" => publisher_schema()
      }
    ]
  end

  def article_url(slug), do: @site_url <> "/blog/" <> slug

  defp website_schema do
    %{
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => @site_name,
      "url" => @site_url,
      "description" => @default_description,
      "publisher" => publisher_schema()
    }
  end

  defp person_schema do
    %{
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => "David Maraga",
      "jobTitle" => "Former Chief Justice of Kenya",
      "description" =>
        "David Maraga served as Kenya's 14th Chief Justice from October 19, 2016 to January 12, 2021.",
      "image" => default_image_url()
    }
  end

  defp publisher_schema do
    %{
      "@type" => "Organization",
      "name" => @site_name,
      "url" => @site_url
    }
  end
end
