defmodule MaragaInfo.Campaigns.NewsletterBuilderTest do
  use ExUnit.Case, async: true

  alias MaragaInfo.Campaigns.NewsletterBuilder

  test "greeting headline preserves authored casing" do
    html =
      NewsletterBuilder.build_html([
        %{"type" => "greeting", "title" => "Justice Begins with Us"}
      ])

    assert html =~ "Justice Begins with Us"

    refute html =~
             "text-transform:uppercase;font-weight:700;color:#222222;\">Justice Begins with Us"
  end

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

  test "social links use email-safe png icons instead of text marks" do
    html = NewsletterBuilder.build_html([])

    refute html =~ "<svg"
    assert html =~ ~s(src="https://davidmaraga.info/images/social/instagram.png")
    assert html =~ ~s(src="https://davidmaraga.info/images/social/youtube.png")
    assert html =~ ~s(alt="Instagram")
    assert html =~ ~s(alt="YouTube")
    refute html =~ ">IG</span>"
    refute html =~ ">YT</span>"
    refute html =~ ">TT</span>"
  end
end
