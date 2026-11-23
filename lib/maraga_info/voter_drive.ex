defmodule MaragaInfo.VoterDrive do
  import Ecto.Query, warn: false

  alias MaragaInfo.Repo
  alias MaragaInfo.Volunteers.Importer
  alias MaragaInfo.VoterDrive.Registration

  def list_registrations(opts \\ []) do
    Registration
    |> apply_filters(opts)
    |> order_by([registration], desc: registration.registered_on, desc: registration.inserted_at)
    |> maybe_offset(Keyword.get(opts, :offset))
    |> maybe_limit(Keyword.get(opts, :limit))
    |> Repo.all()
  end

  def count_registrations(opts \\ []) do
    Registration
    |> apply_filters(opts)
    |> Repo.aggregate(:count, :id)
  end

  def list_counties do
    Registration
    |> where([r], not is_nil(r.county) and r.county != "")
    |> select([r], r.county)
    |> distinct(true)
    |> order_by([r], asc: r.county)
    |> Repo.all()
  end

  def registration_stats do
    %{
      total: Repo.aggregate(Registration, :count, :id),
      counties:
        Registration
        |> where([registration], not is_nil(registration.county))
        |> select([registration], count(registration.county, :distinct))
        |> Repo.one(),
      with_polling_station:
        Registration
        |> where([registration], not is_nil(registration.polling_station))
        |> Repo.aggregate(:count, :id),
      website:
        Registration
        |> where([registration], is_nil(registration.source_id))
        |> Repo.aggregate(:count, :id)
    }
  end

  def change_registration(%Registration{} = registration, attrs \\ %{}) do
    Registration.public_changeset(registration, attrs)
  end

  def create_registration(attrs) do
    %Registration{}
    |> Registration.public_changeset(attrs)
    |> Repo.insert()
  end

  def import_file(path) do
    with {:ok, rows} <- Importer.parse_file(path) do
      summary =
        Enum.reduce(rows, %{total: 0, inserted: 0, updated: 0, failed: 0}, fn
          {_row, attrs}, summary -> import_row(attrs, summary)
        end)

      {:ok, summary}
    end
  end

  defp import_row(attrs, summary) do
    attrs = Map.put(attrs, :registered_on, Map.get(attrs, :joined_on))
    source_id = attrs[:source_id]

    result =
      case source_id && Repo.get_by(Registration, source_id: source_id) do
        nil -> {:inserted, %Registration{} |> Registration.changeset(attrs) |> Repo.insert()}
        registration -> {:updated, registration |> Registration.changeset(attrs) |> Repo.update()}
      end

    case result do
      {key, {:ok, %Registration{}}} ->
        summary |> Map.update!(:total, &(&1 + 1)) |> Map.update!(key, &(&1 + 1))

      {_key, {:error, _changeset}} ->
        summary |> Map.update!(:total, &(&1 + 1)) |> Map.update!(:failed, &(&1 + 1))
    end
  end

  defp maybe_search(query, nil), do: query
  defp maybe_search(query, ""), do: query

  defp maybe_search(query, term) do
    pattern = "%#{String.trim(term)}%"

    where(
      query,
      [registration],
      ilike(registration.first_name, ^pattern) or
        ilike(registration.last_name, ^pattern) or
        ilike(registration.email, ^pattern) or
        ilike(registration.phone, ^pattern) or
        ilike(registration.county, ^pattern) or
        ilike(registration.constituency, ^pattern)
    )
  end

  defp apply_filters(query, opts) do
    query
    |> maybe_search(Keyword.get(opts, :query))
    |> maybe_filter_county(Keyword.get(opts, :county))
    |> maybe_filter_interest(Keyword.get(opts, :interest))
    |> maybe_filter_source(Keyword.get(opts, :source))
    |> maybe_filter_polling_station(Keyword.get(opts, :polling_station))
  end

  defp maybe_filter_county(query, county) when county in [nil, ""], do: query
  defp maybe_filter_county(query, county), do: where(query, [r], r.county == ^county)

  defp maybe_filter_interest(query, interest) when interest in [nil, ""], do: query
  defp maybe_filter_interest(query, interest), do: where(query, [r], ^interest in r.interests)

  defp maybe_filter_source(query, source) when source in [nil, ""], do: query
  defp maybe_filter_source(query, "website"), do: where(query, [r], is_nil(r.source_id))
  defp maybe_filter_source(query, "imported"), do: where(query, [r], not is_nil(r.source_id))
  defp maybe_filter_source(query, _source), do: query

  defp maybe_filter_polling_station(query, value) when value in [nil, ""], do: query

  defp maybe_filter_polling_station(query, "with") do
    where(query, [r], not is_nil(r.polling_station) and r.polling_station != "")
  end

  defp maybe_filter_polling_station(query, "without") do
    where(query, [r], is_nil(r.polling_station) or r.polling_station == "")
  end

  defp maybe_filter_polling_station(query, _value), do: query

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, ^limit)
  defp maybe_offset(query, nil), do: query
  defp maybe_offset(query, offset), do: offset(query, ^offset)
end
