defmodule MaragaInfo.CampaignsTest do
  use MaragaInfo.DataCase, async: true

  alias MaragaInfo.Campaigns
  alias MaragaInfo.Campaigns.CampaignEmail
  alias MaragaInfo.Campaigns.EmailCampaign

  import MaragaInfo.VolunteersFixtures

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

  test "sms recipients are deduplicated by phone number" do
    volunteer_fixture(%{
      full_name: "Alpha Tester",
      email: "alpha@example.com",
      phone: "0707077707"
    })

    volunteer_fixture(%{
      full_name: "Beta Tester",
      email: "beta@example.com",
      phone: "0707077707"
    })

    volunteer_fixture(%{
      full_name: "Gamma Tester",
      email: "gamma@example.com",
      phone: "0711111111"
    })

    recipients = Campaigns.sms_recipient_pool()

    assert Enum.sort_by(recipients, & &1.phone) == [
             %{phone: "0707077707", name: "Alpha Tester"},
             %{phone: "0711111111", name: "Gamma Tester"}
           ]

    assert Campaigns.sms_recipient_count() == 2
  end
end
