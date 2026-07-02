defmodule MaragaInfo.Campaigns.NewsletterBuilderTest do
  use ExUnit.Case, async: true

  alias MaragaInfo.Campaigns.NewsletterBuilder

  test "body text images uploaded through CKEditor are emitted with absolute urls" do
    html =
      NewsletterBuilder.build_html([
        %{
          "type" => "text",
          "body" => ~s(<p>Hello</p><figure class="image"><img src="/uploads/body.jpg"></figure>)
        }
      ])

    assert html =~ ~s(src="https://davidmaraga.info/uploads/body.jpg")
  end

  test "image sections are emitted with absolute urls" do
    html =
      NewsletterBuilder.build_html([
        %{"type" => "image", "url" => "/uploads/section.jpg", "link_url" => "/donate"}
      ])

    assert html =~ ~s(src="https://davidmaraga.info/uploads/section.jpg")
    assert html =~ ~s(href="https://davidmaraga.info/donate")
  end

  test "social links use email-safe text marks instead of inline svg" do
    html = NewsletterBuilder.build_html([])

    refute html =~ "<svg"
    assert html =~ ">IG</span>"
    assert html =~ ">YT</span>"
  end
end
