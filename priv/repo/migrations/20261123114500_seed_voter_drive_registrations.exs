defmodule MaragaInfo.Repo.Migrations.SeedVoterDriveRegistrations do
  use Ecto.Migration

  def up do
    workbook = Application.app_dir(:maraga_info, "priv/repo/data/volunteers_export.xlsx")

    rows =
      case MaragaInfo.Volunteers.Importer.parse_file(workbook) do
        {:ok, rows} -> rows
        {:error, reason} -> raise "could not seed voter-drive workbook: #{inspect(reason)}"
      end

    existing_source_ids =
      repo()
      |> Ecto.Adapters.SQL.query!(
        "SELECT source_id FROM voter_drive_registrations WHERE source_id IS NOT NULL",
        []
      )
      |> Map.fetch!(:rows)
      |> Enum.map(fn [source_id] -> source_id end)
      |> MapSet.new()

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    rows
    |> Enum.reject(fn {_row_number, attrs} ->
      MapSet.member?(existing_source_ids, attrs[:source_id])
    end)
    |> Enum.map(fn {_row_number, attrs} -> registration(attrs, now) end)
    |> Enum.chunk_every(500)
    |> Enum.each(&repo().insert_all("voter_drive_registrations", &1))
  end

  def down, do: :ok

  defp registration(attrs, now) do
    %{
      source_id: attrs[:source_id],
      first_name: blank_to_nil(attrs[:first_name]),
      last_name: blank_to_nil(attrs[:last_name]),
      phone: blank_to_nil(attrs[:phone]),
      email: attrs[:email] |> String.trim() |> String.downcase(),
      county: blank_to_nil(attrs[:county]),
      constituency: blank_to_nil(attrs[:constituency]),
      ward: blank_to_nil(attrs[:ward]),
      polling_station: blank_to_nil(attrs[:polling_station]),
      interests: attrs[:interests] || [],
      additional_info: blank_to_nil(attrs[:additional_info]),
      registered_on: attrs[:joined_on],
      source_updated_on: attrs[:source_updated_on],
      inserted_at: now,
      updated_at: now
    }
  end

  defp blank_to_nil(value) when value in [nil, ""], do: nil

  defp blank_to_nil(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end
end
