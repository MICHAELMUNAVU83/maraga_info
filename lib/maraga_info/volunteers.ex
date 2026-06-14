defmodule MaragaInfo.Volunteers do
  @moduledoc """
  The Volunteers context.
  """

  import Ecto.Query, warn: false

  alias MaragaInfo.Repo
  alias MaragaInfo.Volunteers.Importer
  alias MaragaInfo.Volunteers.Volunteer

  def list_volunteers(opts \\ []) do
    Volunteer
    |> maybe_search(Keyword.get(opts, :query))
    |> order_by([volunteer],
      desc: volunteer.source_updated_on,
      desc: volunteer.joined_on,
      desc: volunteer.updated_at
    )
    |> maybe_offset(Keyword.get(opts, :offset))
    |> maybe_limit(Keyword.get(opts, :limit))
    |> Repo.all()
  end

  def count_volunteers(opts \\ []) do
    Volunteer
    |> maybe_search(Keyword.get(opts, :query))
    |> Repo.aggregate(:count, :id)
  end

  def volunteer_stats do
    %{
      total: Repo.aggregate(Volunteer, :count, :id),
      with_phone:
        count_where(dynamic([volunteer], not is_nil(volunteer.phone) and volunteer.phone != "")),
      with_location:
        count_where(dynamic([volunteer], not is_nil(volunteer.county) and volunteer.county != "")),
      with_notes:
        count_where(
          dynamic(
            [volunteer],
            not is_nil(volunteer.additional_info) and volunteer.additional_info != ""
          )
        )
    }
  end

  def get_volunteer!(id), do: Repo.get!(Volunteer, id)

  def get_volunteer_by_email(email) when is_binary(email) do
    email = Volunteer.normalize_email(email)
    Repo.get_by(Volunteer, email: email)
  end

  def get_volunteer_by_email(_email), do: nil

  def create_volunteer(attrs \\ %{}) do
    %Volunteer{}
    |> Volunteer.changeset(attrs)
    |> Repo.insert()
  end

  def update_volunteer(%Volunteer{} = volunteer, attrs) do
    volunteer
    |> Volunteer.changeset(attrs)
    |> Repo.update()
  end

  def delete_volunteer(%Volunteer{} = volunteer) do
    Repo.delete(volunteer)
  end

  def change_volunteer(%Volunteer{} = volunteer, attrs \\ %{}) do
    Volunteer.changeset(volunteer, attrs)
  end

  def upsert_volunteer(attrs) do
    attrs = Map.new(attrs)
    email = attrs |> Map.get(:email) || Map.get(attrs, "email")

    case get_volunteer_by_email(email) do
      nil ->
        case create_volunteer(attrs) do
          {:ok, volunteer} -> {:ok, :inserted, volunteer}
          {:error, changeset} -> {:error, changeset}
        end

      %Volunteer{} = volunteer ->
        volunteer
        |> update_volunteer(non_blank_attrs(attrs))
        |> case do
          {:ok, updated} -> {:ok, :updated, updated}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  def import_volunteers_from_file(path) when is_binary(path) do
    with {:ok, rows} <- Importer.parse_file(path) do
      summary =
        Enum.reduce(rows, %{total_rows: 0, inserted: 0, updated: 0, failed: 0, errors: []}, fn
          {row_number, attrs}, acc ->
            case upsert_volunteer(attrs) do
              {:ok, :inserted, _volunteer} ->
                %{acc | total_rows: acc.total_rows + 1, inserted: acc.inserted + 1}

              {:ok, :updated, _volunteer} ->
                %{acc | total_rows: acc.total_rows + 1, updated: acc.updated + 1}

              {:error, changeset} ->
                error =
                  changeset
                  |> errors_to_sentence()
                  |> then(&"Row #{row_number}: #{&1}")

                %{
                  acc
                  | total_rows: acc.total_rows + 1,
                    failed: acc.failed + 1,
                    errors: Enum.take(acc.errors ++ [error], -5)
                }
            end
        end)

      {:ok, summary}
    end
  end

  defp maybe_search(queryable, nil), do: queryable
  defp maybe_search(queryable, ""), do: queryable

  defp maybe_search(queryable, query) do
    pattern = "%#{String.trim(query)}%"

    where(
      queryable,
      [volunteer],
      fragment("coalesce(?, '') ILIKE ?", volunteer.full_name, ^pattern) or
        fragment("coalesce(?, '') ILIKE ?", volunteer.email, ^pattern) or
        fragment("coalesce(?, '') ILIKE ?", volunteer.phone, ^pattern) or
        fragment("coalesce(?, '') ILIKE ?", volunteer.county, ^pattern) or
        fragment("coalesce(?, '') ILIKE ?", volunteer.constituency, ^pattern)
    )
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, ^limit)

  defp maybe_offset(query, nil), do: query
  defp maybe_offset(query, offset), do: offset(query, ^offset)

  defp count_where(dynamic_expr) do
    Volunteer
    |> where(^dynamic_expr)
    |> select([volunteer], count(volunteer.id))
    |> Repo.one()
  end

  defp non_blank_attrs(attrs) do
    attrs
    |> Enum.reject(fn {_key, value} -> blank?(value) end)
    |> Map.new()
  end

  defp blank?(value) when value in [nil, ""], do: true
  defp blank?(_value), do: false

  defp errors_to_sentence(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.flat_map(fn {field, messages} ->
      Enum.map(messages, fn message -> "#{field} #{message}" end)
    end)
    |> Enum.join(", ")
  end
end
