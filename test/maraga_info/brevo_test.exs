defmodule MaragaInfo.BrevoTest do
  use ExUnit.Case, async: true

  alias MaragaInfo.Brevo

  describe "build_payload/1" do
    test "normalizes the Brevo email shape" do
      assert {:ok, payload} =
               Brevo.build_payload(%{
                 sender: %{name: "Alex from Brevo", email: "hello@brevo.com"},
                 to: [%{email: "johndoe@example.com", name: "John Doe"}],
                 subject: "Hello from Brevo!",
                 html_content:
                   "<html><head></head><body><p>Hello,</p><p>This is my first transactional email sent from Brevo.</p></body></html>"
               })

      assert payload == %{
               sender: %{name: "Alex from Brevo", email: "hello@brevo.com"},
               to: [%{email: "johndoe@example.com", name: "John Doe"}],
               subject: "Hello from Brevo!",
               htmlContent:
                 "<html><head></head><body><p>Hello,</p><p>This is my first transactional email sent from Brevo.</p></body></html>"
             }
    end
  end
end
