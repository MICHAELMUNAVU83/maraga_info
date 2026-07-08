defmodule MaragaInfoWeb.Admin.SmsAnalyticsLiveTest do
  use MaragaInfoWeb.ConnCase

  import Phoenix.LiveViewTest

  alias MaragaInfo.Campaigns.SmsCampaign
  alias MaragaInfo.Campaigns.SmsDelivery
  alias MaragaInfo.Repo

  describe "analytics page" do
    setup [:register_and_log_in_user]

    test "shows sms campaign delivery analytics and UTC+3 timestamps", %{conn: conn} do
      campaign =
        Repo.insert!(%SmsCampaign{
          title: "County organisers blast",
          sender_id: "Maraga 27",
          message: "Hello",
          callback_url: "https://example.com/callback",
          status: "sent",
          recipient_count: 2,
          sent_count: 1,
          failed_count: 1,
          sent_at: ~U[2026-07-08 09:30:00Z],
          inserted_at: ~U[2026-07-08 08:00:00Z],
          updated_at: ~U[2026-07-08 09:30:00Z]
        })

      Repo.insert!(%SmsDelivery{
        campaign_id: campaign.id,
        phone: "0700123456",
        name: "Alice",
        status: "sent",
        provider_response: "{\"status\":\"ok\"}",
        sent_at: ~U[2026-07-08 09:15:00Z],
        inserted_at: ~U[2026-07-08 08:05:00Z],
        updated_at: ~U[2026-07-08 09:15:00Z]
      })

      Repo.insert!(%SmsDelivery{
        campaign_id: campaign.id,
        phone: "0711223344",
        name: "Bob",
        status: "failed",
        error: "provider timeout",
        inserted_at: ~U[2026-07-08 08:10:00Z],
        updated_at: ~U[2026-07-08 09:25:00Z]
      })

      {:ok, _live, html} = live(conn, ~p"/admin/sms/#{campaign.id}/analytics")

      assert html =~ "County organisers blast analytics"
      assert html =~ "0700123456"
      assert html =~ "0711223344"
      assert html =~ "UTC+3"
      assert html =~ "08 Jul 2026, 12:15 UTC+3"
      assert html =~ "08 Jul 2026, 12:30 UTC+3"
      assert html =~ "50%"
      assert html =~ "provider timeout"
      assert html =~ "status"
    end
  end
end
