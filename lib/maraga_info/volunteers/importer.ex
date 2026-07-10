defmodule MaragaInfo.Volunteers.Importer do
  @moduledoc """
  Parses volunteer spreadsheets exported as `.xlsx`.
  """

  @header_map %{
    "ID" => :source_id,
    "First Name" => :first_name,
    "Last Name" => :last_name,
    "Full Name" => :full_name,
    "Email" => :email,
    "Phone" => :phone,
    "County" => :county,
    "Constituency" => :constituency,
    "Ward" => :ward,
    "Polling Station" => :polling_station,
    "Additional Info" => :additional_info,
    "Joined Date" => :joined_on,
    "Last Updated" => :source_updated_on
  }

  @type row_attrs :: %{optional(atom()) => term()}
  @type parsed_row :: {pos_integer(), row_attrs()}

  def parse_file(path) when is_binary(path) do
    with {:ok, entries} <- zip_entries(path),
         {:ok, workbook_xml} <- fetch_entry(entries, "xl/workbook.xml"),
         {:ok, rels_xml} <- fetch_entry(entries, "xl/_rels/workbook.xml.rels"),
         {:ok, shared_strings} <- parse_shared_strings(entries),
         {:ok, sheet_path} <- first_sheet_path(workbook_xml, rels_xml),
         {:ok, worksheet_xml} <- fetch_entry(entries, sheet_path),
         {:ok, rows} <- parse_rows(worksheet_xml, shared_strings) do
      {:ok, rows_to_attrs(rows)}
    else
      {:error, _reason} = error -> error
      _ -> {:error, :invalid_spreadsheet}
    end
  end

  defp zip_entries(path) do
    case :zip.extract(String.to_charlist(path), [:memory]) do
      {:ok, entries} ->
        {:ok, Map.new(entries, fn {name, content} -> {to_string(name), content} end)}

      {:error, _reason} ->
        {:error, :invalid_spreadsheet}
    end
  end

  defp fetch_entry(entries, path) do
    case Map.fetch(entries, path) do
      {:ok, content} -> {:ok, content}
      :error -> {:error, :invalid_spreadsheet}
    end
  end

  defp first_sheet_path(workbook_xml, rels_xml) do
    with {:ok, workbook} <- parse_xml(workbook_xml),
         {:ok, rels} <- parse_xml(rels_xml),
         [sheet | _] <-
           xpath_nodes(
             workbook,
             "/*[local-name()='workbook']/*[local-name()='sheets']/*[local-name()='sheet']"
           ),
         rel_id when rel_id != "" <- xpath_string(sheet, "string(@*[local-name()='id'])"),
         [relationship | _] <-
           xpath_nodes(
             rels,
             "/*[local-name()='Relationships']/*[local-name()='Relationship'][@Id='#{rel_id}']"
           ),
         target when target != "" <- xpath_string(relationship, "string(@Target)") do
      {:ok, Path.join("xl", target)}
    else
      _ -> {:error, :invalid_spreadsheet}
    end
  end

  defp parse_shared_strings(entries) do
    case Map.fetch(entries, "xl/sharedStrings.xml") do
      {:ok, shared_strings_xml} -> parse_shared_strings_xml(shared_strings_xml)
      :error -> {:ok, []}
    end
  end

  defp parse_shared_strings_xml(shared_strings_xml) do
    with {:ok, document} <- parse_xml(shared_strings_xml) do
      strings =
        document
        |> xpath_nodes("/*[local-name()='sst']/*[local-name()='si']")
        |> Enum.map(fn item ->
          item
          |> xpath_nodes(".//*[local-name()='t']")
          |> Enum.map_join("", &xpath_string(&1, "string(.)"))
        end)

      {:ok, strings}
    end
  end

  defp parse_rows(worksheet_xml, shared_strings) do
    with {:ok, worksheet} <- parse_xml(worksheet_xml) do
      rows =
        worksheet
        |> xpath_nodes(
          "/*[local-name()='worksheet']/*[local-name()='sheetData']/*[local-name()='row']"
        )
        |> Enum.map(&parse_row(&1, shared_strings))

      {:ok, rows}
    end
  end

  defp parse_row(row, shared_strings) do
    row
    |> xpath_nodes("*[local-name()='c']")
    |> Enum.reduce(%{}, fn cell, acc ->
      column =
        cell
        |> xpath_string("string(@r)")
        |> column_reference()

      Map.put(acc, column, parse_cell_value(cell, shared_strings))
    end)
  end

  defp parse_cell_value(cell, shared_strings) do
    case xpath_string(cell, "string(@t)") do
      "inlineStr" ->
        xpath_string(cell, "string(.//*[local-name()='t'])")

      "str" ->
        xpath_string(cell, "string(*[local-name()='v'])")

      "s" ->
        cell
        |> xpath_string("string(*[local-name()='v'])")
        |> Integer.parse()
        |> case do
          {index, _rest} -> Enum.at(shared_strings, index, "")
          :error -> ""
        end

      _other ->
        xpath_string(cell, "string(*[local-name()='v'])")
    end
  end

  defp rows_to_attrs([]), do: []

  defp rows_to_attrs([header_row | data_rows]) do
    headers = header_row_to_list(header_row)

    data_rows
    |> Enum.with_index(2)
    |> Enum.map(fn {row_map, row_number} ->
      attrs =
        headers
        |> Enum.with_index()
        |> Enum.reduce(%{}, fn {header, index}, acc ->
          value = Map.get(row_map, index)

          case Map.fetch(@header_map, header) do
            {:ok, field} -> Map.put(acc, field, cast_value(field, value))
            :error -> acc
          end
        end)

      {row_number, attrs}
    end)
    |> Enum.reject(fn {_row_number, attrs} -> blank_row?(attrs) end)
  end

  defp header_row_to_list(header_row) do
    case Map.keys(header_row) do
      [] ->
        []

      keys ->
        for index <- 0..Enum.max(keys) do
          header_row
          |> Map.get(index)
          |> to_string_or_nil()
          |> case do
            nil -> ""
            value -> String.trim(value)
          end
        end
    end
  end

  defp cast_value(field, value) when field in [:joined_on, :source_updated_on] do
    parse_date(value)
  end

  defp cast_value(_field, value) do
    value
    |> to_string_or_nil()
    |> case do
      nil -> nil
      text -> String.trim(text)
    end
  end

  defp parse_date(nil), do: nil

  defp parse_date(value) when is_binary(value) do
    trimmed = String.trim(value)

    cond do
      trimmed == "" ->
        nil

      Regex.match?(~r/^\d{1,2}\/\d{1,2}\/\d{4}$/, trimmed) ->
        case String.split(trimmed, "/") do
          [day, month, year] ->
            Date.new(String.to_integer(year), String.to_integer(month), String.to_integer(day))
            |> case do
              {:ok, date} -> date
              _ -> nil
            end

          _ ->
            nil
        end

      Regex.match?(~r/^\d+(\.\d+)?$/, trimmed) ->
        trimmed
        |> Float.parse()
        |> case do
          {serial, _} -> Date.add(~D[1899-12-30], trunc(serial))
          :error -> nil
        end

      true ->
        case Date.from_iso8601(trimmed) do
          {:ok, date} -> date
          _ -> nil
        end
    end
  end

  defp parse_date(_value), do: nil

  defp blank_row?(attrs) do
    Enum.all?(attrs, fn {_key, value} -> blank_value?(value) end)
  end

  defp blank_value?(value) when value in [nil, ""], do: true
  defp blank_value?(_value), do: false

  defp column_reference(reference) do
    reference
    |> String.replace(~r/\d+/, "")
    |> column_to_index()
  end

  defp column_to_index(column) do
    column
    |> String.upcase()
    |> String.to_charlist()
    |> Enum.reduce(0, fn char, acc -> acc * 26 + char - ?A + 1 end)
    |> Kernel.-(1)
  end

  defp parse_xml(binary) do
    sanitized_xml = sanitize_for_xmerl(binary)

    try do
      {document, _rest} = :xmerl_scan.string(String.to_charlist(sanitized_xml), quiet: true)
      {:ok, document}
    rescue
      _ -> {:error, :invalid_spreadsheet}
    catch
      :exit, _reason -> {:error, :invalid_spreadsheet}
    end
  end

  defp xpath_nodes(node, expression) do
    :xmerl_xpath.string(String.to_charlist(expression), node)
  end

  defp xpath_string(node, expression) do
    case :xmerl_xpath.string(String.to_charlist(expression), node) do
      {:xmlObj, :string, value} -> List.to_string(value)
      value when is_list(value) -> List.to_string(value)
      _ -> ""
    end
  end

  defp to_string_or_nil(nil), do: nil
  defp to_string_or_nil(value) when is_binary(value), do: value
  defp to_string_or_nil(value), do: to_string(value)

  defp sanitize_for_xmerl(binary) when is_binary(binary) do
    binary
    |> decode_xml_codepoints()
    |> Enum.map(&encode_xmerl_safe_codepoint/1)
    |> IO.iodata_to_binary()
  end

  defp decode_xml_codepoints(binary), do: decode_xml_codepoints(binary, [])

  defp decode_xml_codepoints(<<>>, acc), do: Enum.reverse(acc)

  defp decode_xml_codepoints(<<codepoint::utf8, rest::binary>>, acc) do
    decode_xml_codepoints(rest, [codepoint | acc])
  end

  defp decode_xml_codepoints(<<byte, rest::binary>>, acc) do
    decode_xml_codepoints(rest, [windows_1252_codepoint(byte) | acc])
  end

  defp encode_xmerl_safe_codepoint(codepoint) when codepoint in [9, 10, 13] do
    <<codepoint::utf8>>
  end

  defp encode_xmerl_safe_codepoint(codepoint) when codepoint < 32 do
    ""
  end

  defp encode_xmerl_safe_codepoint(codepoint) when codepoint > 127 do
    "&#" <> Integer.to_string(codepoint) <> ";"
  end

  defp encode_xmerl_safe_codepoint(codepoint) do
    <<codepoint::utf8>>
  end

  defp windows_1252_codepoint(0x80), do: 8364
  defp windows_1252_codepoint(0x81), do: ?\s
  defp windows_1252_codepoint(0x82), do: 8218
  defp windows_1252_codepoint(0x83), do: 402
  defp windows_1252_codepoint(0x84), do: 8222
  defp windows_1252_codepoint(0x85), do: 8230
  defp windows_1252_codepoint(0x86), do: 8224
  defp windows_1252_codepoint(0x87), do: 8225
  defp windows_1252_codepoint(0x88), do: 710
  defp windows_1252_codepoint(0x89), do: 8240
  defp windows_1252_codepoint(0x8A), do: 352
  defp windows_1252_codepoint(0x8B), do: 8249
  defp windows_1252_codepoint(0x8C), do: 338
  defp windows_1252_codepoint(0x8D), do: ?\s
  defp windows_1252_codepoint(0x8E), do: 381
  defp windows_1252_codepoint(0x8F), do: ?\s
  defp windows_1252_codepoint(0x90), do: ?\s
  defp windows_1252_codepoint(0x91), do: 8216
  defp windows_1252_codepoint(0x92), do: 8217
  defp windows_1252_codepoint(0x93), do: 8220
  defp windows_1252_codepoint(0x94), do: 8221
  defp windows_1252_codepoint(0x95), do: 8226
  defp windows_1252_codepoint(0x96), do: 8211
  defp windows_1252_codepoint(0x97), do: 8212
  defp windows_1252_codepoint(0x98), do: 732
  defp windows_1252_codepoint(0x99), do: 8482
  defp windows_1252_codepoint(0x9A), do: 353
  defp windows_1252_codepoint(0x9B), do: 8250
  defp windows_1252_codepoint(0x9C), do: 339
  defp windows_1252_codepoint(0x9D), do: ?\s
  defp windows_1252_codepoint(0x9E), do: 382
  defp windows_1252_codepoint(0x9F), do: 376
  defp windows_1252_codepoint(byte), do: byte
end
