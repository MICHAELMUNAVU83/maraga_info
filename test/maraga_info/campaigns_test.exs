defmodule MaragaInfo.CampaignsTest do
  use ExUnit.Case, async: true

  alias MaragaInfo.Campaigns.CampaignEmail
  alias MaragaInfo.Campaigns.EmailCampaign

  test "build personalizes the first name when provided" do
    campaign = %EmailCampaign{
      subject: "Hello {{first_name}}",
      sender_name: "David Maraga Campaign",
      body: "<p>Hello {{first_name}}, thank you for standing with us.</p>"
    }

    email =
      CampaignEmail.build(
        campaign,
        "A",
        %{email: "tester@example.com", name: "Michael"},
        "no-reply@example.com"
      )

    assert email.subject == "Hello Michael"
    assert {"Michael", "tester@example.com"} in email.to
    assert email.html_body =~ "Hello Michael, thank you for standing with us."
    assert email.text_body =~ "Hello Michael, thank you for standing with us."
  end

  test "build falls back to Friend when recipient name is blank" do
    campaign = %EmailCampaign{
      subject: "Hello {{first_name}}",
      sender_name: "David Maraga Campaign",
      body: "<p>Hello {{first_name}}, welcome aboard.</p>"
    }

    email =
      CampaignEmail.build(
        campaign,
        "A",
        %{email: "tester@example.com", name: "   "},
        "no-reply@example.com"
      )

    assert email.subject == "Hello Friend"
    assert email.html_body =~ "Hello Friend, welcome aboard."
    assert email.text_body =~ "Hello Friend, welcome aboard."
  end
end
