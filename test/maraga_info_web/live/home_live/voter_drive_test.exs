defmodule MaragaInfoWeb.HomeLive.VoterDriveTest do
  use MaragaInfoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaragaInfo.Repo
  alias MaragaInfo.VoterDrive.Registration

  test "collects a voter-drive registration in its separate table", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Volunteer for Kenya"

    attrs = %{
      "first_name" => "Amina",
      "last_name" => "Wanjiku",
      "phone" => "+254700000001",
      "email" => "AMINA@example.com",
      "county" => "Nairobi",
      "constituency" => "Westlands",
      "ward" => "Parklands",
      "polling_station" => "Parklands Primary",
      "interests" => ["Civic Education", "Digital Organizing"],
      "additional_info" => "Available on weekends"
    }

    html = view |> form("#volunteer-form", volunteer: attrs) |> render_submit()

    assert html =~ "Thank you for stepping forward"

    registration = Repo.get_by!(Registration, email: "amina@example.com")
    assert registration.county == "Nairobi"
    assert registration.interests == ["Civic Education", "Digital Organizing"]
  end

  test "requires an interest and location details", %{conn: conn} do
    initial_count = Repo.aggregate(Registration, :count)
    {:ok, view, _html} = live(conn, ~p"/")

    html =
      view
      |> form("#volunteer-form",
        volunteer: %{
          "first_name" => "Amina",
          "last_name" => "Wanjiku",
          "phone" => "+254700000001",
          "email" => "amina@example.com",
          "county" => "",
          "constituency" => "",
          "ward" => "",
          "interests" => []
        }
      )
      |> render_submit()

    assert html =~ "can&#39;t be blank"
    assert Repo.aggregate(Registration, :count) == initial_count
  end
end
