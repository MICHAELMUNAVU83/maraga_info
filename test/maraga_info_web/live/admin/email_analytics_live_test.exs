defmodule MaragaInfoWeb.Admin.EmailAnalyticsLiveTest do
  use MaragaInfoWeb.ConnCase

  import Phoenix.LiveViewTest

  alias MaragaInfo.Campaigns.EmailCampaign
  alias MaragaInfo.Campaigns.EmailDelivery
  alias MaragaInfo.Repo

  describe "analytics page" do
    setup [:register_and_log_in_user]

    test "shows campaign delivery analytics and UTC+3 timestamps", %{conn: conn} do
      campaign =
        Repo.insert!(%EmailCampaign{
          subject: "July Movement Update",
          body: "<p>Hello</p>",
          sender_name: "Maraga Campaign",
          status: "sent",
          recipient_count: 2,
          sent_count: 1,
          failed_count: 1,
          sent_at: ~U[2026-07-08 09:30:00Z],
          inserted_at: ~U[2026-07-08 08:00:00Z],
          updated_at: ~U[2026-07-08 09:30:00Z]
        })

      Repo.insert!(%EmailDelivery{
        campaign_id: campaign.id,
        email: "alice@example.com",
        name: "Alice",
        variant: "A",
        status: "sent",
        sent_at: ~U[2026-07-08 09:15:00Z],
        inserted_at: ~U[2026-07-08 08:05:00Z],
        updated_at: ~U[2026-07-08 09:15:00Z]
      })

      Repo.insert!(%EmailDelivery{
        campaign_id: campaign.id,
        email: "bob@example.com",
        name: "Bob",
        variant: "A",
        status: "failed",
        error: "mailbox unavailable",
        inserted_at: ~U[2026-07-08 08:10:00Z],
        updated_at: ~U[2026-07-08 09:25:00Z]
      })

      {:ok, _live, html} = live(conn, ~p"/admin/emails/#{campaign.id}/analytics")

      assert html =~ "July Movement Update analytics"
      assert html =~ "alice@example.com"
      assert html =~ "bob@example.com"
      assert html =~ "UTC+3"
      assert html =~ "08 Jul 2026, 12:15 UTC+3"
      assert html =~ "08 Jul 2026, 12:30 UTC+3"
      assert html =~ "50%"
      assert html =~ "mailbox unavailable"
    end
  end
end
