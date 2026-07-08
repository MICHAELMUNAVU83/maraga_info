defmodule MaragaInfo.VolunteersTest do
  use MaragaInfo.DataCase

  alias MaragaInfo.Volunteers

  import MaragaInfo.VolunteersFixtures

  @allowed_access_emails [
    "infodesk@davidmaraga.com",
    "michaelmunavu83@gmail.com"
  ]

  describe "create_volunteer/1" do
    test "normalizes email and keeps it unique" do
      volunteer = volunteer_fixture(%{email: "FirstVolunteer@Example.com "})

      assert volunteer.email == "firstvolunteer@example.com"

      assert {:error, changeset} =
               Volunteers.create_volunteer(%{
                 email: " firstvolunteer@example.com",
                 first_name: "Duplicate"
               })

      assert "has already been taken" in errors_on(changeset).email
    end
  end

  describe "import_volunteers_from_file/1" do
    test "inserts new volunteers and updates matching emails" do
      path =
        volunteer_import_file!([
          [
            "100",
            "John",
            "Doe",
            "John Doe",
            "john@example.com",
            "0700000000",
            "Nairobi City",
            "Kasarani",
            "Ruai",
            "Ngundu Primary School",
            "Original note",
            "11/05/2026",
            "11/05/2026"
          ],
          [
            "101",
            "Jane",
            "Roe",
            "Jane Roe",
            "jane@example.com",
            "0711111111",
            "Kiambu",
            "Kiambaa",
            "Muchatha",
            "Muchatha Pri Sch",
            "Strong mobiliser",
            "12/05/2026",
            "12/05/2026"
          ],
          [
            "102",
            "John",
            "Doe",
            "John Doe",
            "john@example.com",
            "0799999999",
            "Nairobi City",
            "Kasarani",
            "Ruai",
            "",
            "",
            "11/05/2026",
            "13/05/2026"
          ]
        ])

      assert {:ok, summary} = Volunteers.import_volunteers_from_file(path)
      assert summary.inserted == 2
      assert summary.updated == 1
      assert summary.failed == 0

      john = Volunteers.get_volunteer_by_email("JOHN@example.com")
      jane = Volunteers.get_volunteer_by_email("jane@example.com")

      assert john.phone == "0799999999"
      assert john.polling_station == "Ngundu Primary School"
      assert john.additional_info == "Original note"
      assert john.source_updated_on == ~D[2026-05-13]

      assert jane.full_name == "Jane Roe"
      assert jane.county == "Kiambu"

      assert length(Volunteers.list_volunteers()) == 2
    end

    test "imports spreadsheet rows with unicode punctuation in text fields" do
      path =
        volunteer_import_file!([
          [
            "200",
            "Naomi",
            "Otolo",
            "Naomi Otolo",
            "naomi@example.com",
            "0722222222",
            "Kakamega",
            "Butere",
            "Marama Central",
            "Esherembe Primary School",
            "For such a time as this. Esther 4:14.”",
            "10/05/2026",
            "10/05/2026"
          ]
        ])

      assert {:ok, summary} = Volunteers.import_volunteers_from_file(path)
      assert summary.inserted == 1
      assert summary.updated == 0
      assert summary.failed == 0

      volunteer = Volunteers.get_volunteer_by_email("naomi@example.com")
      assert volunteer.additional_info == "For such a time as this. Esther 4:14.”"
    end
  end

  describe "request_volunteer_access_code/1" do
    test "creates codes only for whitelisted emails" do
      for email <- @allowed_access_emails do
        assert {:ok, access_code} = Volunteers.request_volunteer_access_code(String.upcase(email))
        assert access_code.email == email
      end
    end

    test "rejects non-whitelisted emails" do
      assert {:error, :invalid_email} =
               Volunteers.request_volunteer_access_code("viewer@example.com")
    end
  end
end
