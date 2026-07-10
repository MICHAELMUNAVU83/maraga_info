defmodule MaragaInfoWeb.Admin.VolunteerLiveTest do
  use MaragaInfoWeb.ConnCase

  import Phoenix.LiveViewTest
  import MaragaInfo.VolunteersFixtures
  import Swoosh.TestAssertions

  alias MaragaInfo.Repo
  alias MaragaInfo.Volunteers
  alias MaragaInfo.Volunteers.VolunteerAccessCode

  @allowed_access_email "infodesk@davidmaraga.com"
  @allowed_access_code "123456"

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
    setup :set_swoosh_global
    setup :require_volunteer_code

    test "adds a volunteer manually from the popup", %{conn: conn} do
      {:ok, live, html} = open_unlocked_volunteer_live(conn)

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

      {:ok, live, _html} = open_unlocked_volunteer_live(conn)

      live
      |> element("#open-volunteer-modal")
      |> render_click()

      live
      |> element("button[phx-click=\"switch_form_tab\"][phx-value-tab=\"import\"]")
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

      {:ok, live, html} = open_unlocked_volunteer_live(conn)

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

    test "requires an emailed access code before showing volunteer data", %{conn: conn} do
      volunteer_fixture(%{email: "hidden@example.com", first_name: "Hidden"})

      {:ok, live, html} = live(conn, ~p"/admin/volunteers")

      assert html =~ "Volunteer list locked"
      refute html =~ "hidden@example.com"

      set_swoosh_global()

      html =
        live
        |> form("#volunteer-access-request-form", access: %{email: @allowed_access_email})
        |> render_submit()

      assert html =~ "Access code sent to #{@allowed_access_email}"
      code = insert_access_code!(@allowed_access_email)

      html =
        live
        |> form("#volunteer-access-verify-form",
          access: %{email: @allowed_access_email, code: code}
        )
        |> render_submit()

      assert html =~ "Volunteer list unlocked"
      assert html =~ "hidden@example.com"
      assert html =~ @allowed_access_email
      assert [%{email: @allowed_access_email}] = Volunteers.list_volunteer_views()
    end

    test "shows volunteers immediately when otp gate is disabled in config", %{conn: conn} do
      previous = Application.get_env(:maraga_info, :require_volunteer_code, true)
      Application.put_env(:maraga_info, :require_volunteer_code, false)
      on_exit(fn -> Application.put_env(:maraga_info, :require_volunteer_code, previous) end)

      volunteer_fixture(%{email: "visible@example.com", first_name: "Visible"})

      {:ok, _live, html} = live(conn, ~p"/admin/volunteers")

      refute html =~ "Volunteer list locked"
      refute html =~ "Unlock volunteer list"
      assert html =~ "visible@example.com"
    end

    test "rejects access code requests from non-whitelisted emails", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/admin/volunteers")

      html =
        live
        |> form("#volunteer-access-request-form", access: %{email: "viewer@example.com"})
        |> render_submit()

      assert html =~ "Email is invalid."
      refute html =~ "Access code sent to"
      assert_no_email_sent()
    end

    test "rejects expired access codes", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/admin/volunteers")

      set_swoosh_global()

      live
      |> form("#volunteer-access-request-form", access: %{email: @allowed_access_email})
      |> render_submit()

      code = insert_access_code!(@allowed_access_email)

      expire_access_codes_for(@allowed_access_email)

      html =
        live
        |> form("#volunteer-access-verify-form",
          access: %{email: @allowed_access_email, code: code}
        )
        |> render_submit()

      assert html =~ "That code is invalid or has expired"
      assert Volunteers.list_volunteer_views() == []
    end
  end

  defp expire_access_codes_for(email) do
    import Ecto.Query

    VolunteerAccessCode
    |> where([access_code], access_code.email == ^email)
    |> Repo.update_all(set: [expires_at: ~U[2026-01-01 00:00:00Z]])
  end

  defp require_volunteer_code(_context) do
    previous = Application.get_env(:maraga_info, :require_volunteer_code, true)
    Application.put_env(:maraga_info, :require_volunteer_code, true)
    on_exit(fn -> Application.put_env(:maraga_info, :require_volunteer_code, previous) end)
    :ok
  end

  defp open_unlocked_volunteer_live(conn) do
    {:ok, live, _html} = live(conn, ~p"/admin/volunteers")

    live
    |> form("#volunteer-access-request-form", access: %{email: @allowed_access_email})
    |> render_submit()

    code = insert_access_code!(@allowed_access_email)

    html =
      live
      |> form("#volunteer-access-verify-form",
        access: %{email: @allowed_access_email, code: code}
      )
      |> render_submit()

    {:ok, live, html}
  end

  defp insert_access_code!(email) do
    salt = Ecto.UUID.generate()

    %VolunteerAccessCode{}
    |> VolunteerAccessCode.changeset(%{
      email: email,
      code_hash: hash_access_code(@allowed_access_code, salt),
      salt: salt,
      expires_at: DateTime.add(DateTime.utc_now() |> DateTime.truncate(:second), 120, :second)
    })
    |> Repo.insert!()

    @allowed_access_code
  end

  defp hash_access_code(code, salt) do
    :crypto.hash(:sha256, "#{salt}:#{code}")
    |> Base.encode16(case: :lower)
  end
end
