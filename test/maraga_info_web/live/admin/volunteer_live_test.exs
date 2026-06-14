defmodule MaragaInfoWeb.Admin.VolunteerLiveTest do
  use MaragaInfoWeb.ConnCase

  import Phoenix.LiveViewTest
  import MaragaInfo.VolunteersFixtures

  alias MaragaInfo.Volunteers

  @create_attrs %{
    first_name: "Grace",
    last_name: "Wanjiru",
    email: "grace@example.com",
    phone: "0700123456",
    county: "Nairobi City",
    constituency: "Westlands",
    ward: "Parklands",
    polling_station: "City Primary School",
    joined_on: "2026-05-11",
    additional_info: "Happy to volunteer"
  }

  describe "index" do
    setup [:register_and_log_in_user]

    test "adds a volunteer manually from the popup", %{conn: conn} do
      {:ok, live, html} = live(conn, ~p"/admin/volunteers")

      assert html =~ "Add or import volunteers"
      refute html =~ ~s(id="volunteer-form")

      live
      |> element("#open-volunteer-modal")
      |> render_click()

      assert live
             |> form("#volunteer-form", volunteer: %{email: ""})
             |> render_change() =~ "can&#39;t be blank"

      html =
        live
        |> form("#volunteer-form", volunteer: @create_attrs)
        |> render_submit()

      assert html =~ "Volunteer added"
      assert html =~ "grace@example.com"

      volunteer = Volunteers.get_volunteer_by_email("GRACE@example.com")
      assert volunteer.full_name == "Grace Wanjiru"
    end

    test "imports volunteers from xlsx and updates existing email matches", %{conn: conn} do
      volunteer_fixture(%{
        email: "existing@example.com",
        first_name: "Existing",
        last_name: "Volunteer",
        phone: "0700000000",
        polling_station: "Original Station"
      })

      path =
        volunteer_import_file!([
          [
            "201",
            "Existing",
            "Volunteer",
            "Existing Volunteer",
            "existing@example.com",
            "0791234567",
            "Nairobi City",
            "Westlands",
            "Parklands",
            "",
            "",
            "11/05/2026",
            "12/05/2026"
          ],
          [
            "202",
            "New",
            "Person",
            "New Person",
            "newperson@example.com",
            "0712345678",
            "Kiambu",
            "Kiambaa",
            "Muchatha",
            "Muchatha Pri Sch",
            "Fresh import",
            "12/05/2026",
            "12/05/2026"
          ]
        ])

      {:ok, live, _html} = live(conn, ~p"/admin/volunteers")

      live
      |> element("#open-volunteer-modal")
      |> render_click()

      live
      |> file_input("#volunteer-import-form", :spreadsheet, [
        %{
          name: "volunteers.xlsx",
          content: File.read!(path),
          type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        }
      ])
      |> render_upload("volunteers.xlsx")

      html =
        live
        |> form("#volunteer-import-form", %{})
        |> render_submit()

      assert html =~ "Import finished: 1 added, 1 updated."
      assert html =~ "newperson@example.com"

      existing = Volunteers.get_volunteer_by_email("existing@example.com")
      assert existing.phone == "0791234567"
      assert existing.polling_station == "Original Station"
    end

    test "shows all volunteers with pagination", %{conn: conn} do
      Enum.each(1..30, fn index ->
        volunteer_fixture(%{
          email: "paged#{index}@example.com",
          first_name: "Paged #{index}",
          last_name: "Volunteer",
          source_id: Integer.to_string(index),
          joined_on: Date.add(~D[2026-05-01], index),
          source_updated_on: Date.add(~D[2026-05-01], index)
        })
      end)

      {:ok, live, html} = live(conn, ~p"/admin/volunteers")

      assert html =~ "Showing 1-25 of 30 volunteers"
      assert html =~ "paged30@example.com"
      refute html =~ "paged1@example.com"

      html =
        live
        |> element("button[phx-click=\"next_page\"]")
        |> render_click()

      assert html =~ "Showing 26-30 of 30 volunteers"
      assert html =~ "paged1@example.com"
    end
  end
end
