defmodule MaragaInfo.VolunteersFixtures do
  @moduledoc """
  Test helpers for volunteer records and spreadsheet imports.
  """

  def volunteer_fixture(attrs \\ %{}) do
    unique = System.unique_integer([:positive])

    {:ok, volunteer} =
      attrs
      |> Enum.into(%{
        additional_info: "Ready to help",
        constituency: "Kasarani",
        county: "Nairobi City",
        email: "volunteer#{unique}@example.com",
        first_name: "Test",
        joined_on: ~D[2026-05-11],
        last_name: "Volunteer",
        phone: "070000000#{rem(unique, 10)}",
        polling_station: "Ngundu Primary School",
        source_id: Integer.to_string(unique),
        source_updated_on: ~D[2026-05-11],
        ward: "Ruai"
      })
      |> MaragaInfo.Volunteers.create_volunteer()

    volunteer
  end

  def volunteer_import_file!(rows) when is_list(rows) do
    build_volunteer_import_file!(rows, :inline)
  end

  def volunteer_import_shared_strings_file!(rows) when is_list(rows) do
    build_volunteer_import_file!(rows, :shared_strings)
  end

  defp build_volunteer_import_file!(rows, mode) do
    headers = [
      "ID",
      "First Name",
      "Last Name",
      "Full Name",
      "Email",
      "Phone",
      "County",
      "Constituency",
      "Ward",
      "Polling Station",
      "Additional Info",
      "Joined Date",
      "Last Updated"
    ]

    all_rows = [headers | rows]
    path = Path.join(System.tmp_dir!(), "volunteers-#{System.unique_integer([:positive])}.xlsx")

    entries =
      case mode do
        :inline ->
          [
            {~c"[Content_Types].xml", content_types_xml(false)},
            {~c"_rels/.rels", rels_xml()},
            {~c"xl/workbook.xml", workbook_xml()},
            {~c"xl/_rels/workbook.xml.rels", workbook_rels_xml()},
            {~c"xl/worksheets/sheet1.xml", worksheet_xml(all_rows)}
          ]

        :shared_strings ->
          shared_strings = shared_strings(all_rows)

          [
            {~c"[Content_Types].xml", content_types_xml(true)},
            {~c"_rels/.rels", rels_xml()},
            {~c"xl/workbook.xml", workbook_xml()},
            {~c"xl/_rels/workbook.xml.rels", workbook_rels_xml()},
            {~c"xl/sharedStrings.xml", shared_strings_xml(shared_strings)},
            {~c"xl/worksheets/sheet1.xml", worksheet_shared_strings_xml(all_rows, shared_strings)}
          ]
      end

    {:ok, _path} = :zip.create(String.to_charlist(path), entries)
    path
  end

  defp content_types_xml(include_shared_strings?) do
    shared_strings_override =
      if include_shared_strings? do
        ~s(\n  <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>)
      else
        ""
      end

    ~s(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
#{shared_strings_override}
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>)
  end

  defp rels_xml do
    ~s(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>)
  end

  defp workbook_xml do
    ~s(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Volunteers" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>)
  end

  defp workbook_rels_xml do
    ~s(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>)
  end

  defp worksheet_xml(rows) do
    body =
      rows
      |> Enum.with_index(1)
      |> Enum.map_join("", fn {row, row_index} ->
        cells =
          row
          |> Enum.with_index()
          |> Enum.map_join("", fn {value, column_index} ->
            ref = "#{column_name(column_index)}#{row_index}"
            ~s(<c r="#{ref}" t="inlineStr"><is><t>#{xml_escape(value)}</t></is></c>)
          end)

        ~s(<row r="#{row_index}">#{cells}</row>)
      end)

    ~s(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>#{body}</sheetData>
</worksheet>)
  end

  defp worksheet_shared_strings_xml(rows, shared_strings) do
    string_indexes =
      shared_strings
      |> Enum.with_index()
      |> Map.new()

    body =
      rows
      |> Enum.with_index(1)
      |> Enum.map_join("", fn {row, row_index} ->
        cells =
          row
          |> Enum.with_index()
          |> Enum.map_join("", fn {value, column_index} ->
            ref = "#{column_name(column_index)}#{row_index}"
            index = Map.fetch!(string_indexes, to_string(value || ""))
            ~s(<c r="#{ref}" t="s"><v>#{index}</v></c>)
          end)

        ~s(<row r="#{row_index}">#{cells}</row>)
      end)

    ~s(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>#{body}</sheetData>
</worksheet>)
  end

  defp shared_strings(rows) do
    rows
    |> List.flatten()
    |> Enum.map(&to_string(&1 || ""))
    |> Enum.uniq()
  end

  defp shared_strings_xml(strings) do
    count = length(strings)

    body =
      Enum.map_join(strings, "", fn value ->
        ~s(<si><t>#{xml_escape(value)}</t></si>)
      end)

    ~s(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="#{count}" uniqueCount="#{count}">
  #{body}
</sst>)
  end

  defp column_name(index) do
    index
    |> Kernel.+(1)
    |> do_column_name([])
    |> IO.iodata_to_binary()
  end

  defp do_column_name(0, acc), do: acc

  defp do_column_name(index, acc) do
    remainder = rem(index - 1, 26)
    do_column_name(div(index - 1, 26), [<<remainder + ?A>> | acc])
  end

  defp xml_escape(nil), do: ""

  defp xml_escape(value) do
    value
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
