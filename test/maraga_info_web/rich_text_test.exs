defmodule MaragaInfoWeb.RichTextTest do
  use ExUnit.Case, async: true

  alias MaragaInfoWeb.RichText

  describe "sanitize_email/1" do
    test "keeps CKEditor images and makes local image sources absolute" do
      html =
        ~s(<figure class="image"><img src="/uploads/photo.jpg" alt="Team" width="320"></figure>)

      assert RichText.sanitize_email(html) =~
               ~s(src="https://davidmaraga.info/uploads/photo.jpg")
    end

    test "makes local links absolute for email clients" do
      html = ~s(<p><a href="/news">Read more</a></p>)

      assert RichText.sanitize_email(html) =~ ~s(href="https://davidmaraga.info/news")
    end
  end
end
