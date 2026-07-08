defmodule MaragaInfo.Volunteers do
  @moduledoc """
  The Volunteers context.
  """

  import Ecto.Query, warn: false

  alias MaragaInfo.Repo
  alias MaragaInfo.Volunteers.AccessNotifier
  alias MaragaInfo.Volunteers.Importer
  alias MaragaInfo.Volunteers.Volunteer
  alias MaragaInfo.Volunteers.VolunteerAccessCode
  alias MaragaInfo.Volunteers.VolunteerView

  @access_code_ttl_seconds 120
  @allowed_access_emails MapSet.new([
                           "infodesk@davidmaraga.com",
                           "michaelmunavu83@gmail.com"
                         ])

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

  def list_volunteer_views(opts \\ []) do
    limit = Keyword.get(opts, :limit, 25)

    VolunteerView
    |> order_by([view], desc: view.viewed_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def request_volunteer_access_code(email) when is_binary(email) do
    with {:ok, email} <- normalize_access_email(email) do
      code = generate_access_code()
      salt = Ecto.UUID.generate()
      now = utc_now()

      attrs = %{
        email: email,
        code_hash: hash_access_code(code, salt),
        salt: salt,
        expires_at: DateTime.add(now, @access_code_ttl_seconds, :second)
      }

      with {:ok, access_code} <-
             %VolunteerAccessCode{} |> VolunteerAccessCode.changeset(attrs) |> Repo.insert(),
           {:ok, _email} <- AccessNotifier.deliver_access_code(email, code) do
        {:ok, access_code}
      end
    end
  end

  def request_volunteer_access_code(_email), do: {:error, :invalid_email}

  def verify_volunteer_access_code(email, code) when is_binary(email) and is_binary(code) do
    with {:ok, email} <- normalize_access_email(email),
         {:ok, code} <- normalize_access_code(code),
         {:ok, access_code} <- find_valid_access_code(email, code) do
      now = utc_now()

      Repo.transaction(fn ->
        access_code
        |> Ecto.Changeset.change(used_at: now)
        |> Repo.update!()

        %VolunteerView{}
        |> VolunteerView.changeset(%{
          email: email,
          viewed_at: now,
          access_method: "email_code"
        })
        |> Repo.insert!()
      end)
    end
    |> case do
      {:ok, %VolunteerView{} = view} -> {:ok, view}
      {:error, reason} -> {:error, reason}
    end
  end

  def verify_volunteer_access_code(_email, _code), do: {:error, :invalid_or_expired_code}

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

  defp find_valid_access_code(email, code) do
    now = utc_now()

    VolunteerAccessCode
    |> where([access_code], access_code.email == ^email)
    |> where([access_code], is_nil(access_code.used_at))
    |> where([access_code], access_code.expires_at > ^now)
    |> order_by([access_code], desc: access_code.inserted_at)
    |> limit(10)
    |> Repo.all()
    |> Enum.find(fn access_code ->
      access_code.code_hash == hash_access_code(code, access_code.salt)
    end)
    |> case do
      nil -> {:error, :invalid_or_expired_code}
      access_code -> {:ok, access_code}
    end
  end

  defp normalize_access_email(email) do
    email = Volunteer.normalize_email(email)

    if is_binary(email) and Regex.match?(~r/^[^\s]+@[^\s]+$/, email) and
         MapSet.member?(@allowed_access_emails, email) do
      {:ok, email}
    else
      {:error, :invalid_email}
    end
  end

  defp normalize_access_code(code) do
    code =
      code
      |> String.trim()
      |> String.replace(~r/\D/, "")

    if String.length(code) == 6 do
      {:ok, code}
    else
      {:error, :invalid_or_expired_code}
    end
  end

  defp generate_access_code do
    :crypto.strong_rand_bytes(4)
    |> :binary.decode_unsigned()
    |> rem(1_000_000)
    |> Integer.to_string()
    |> String.pad_leading(6, "0")
  end

  defp hash_access_code(code, salt) do
    :crypto.hash(:sha256, "#{salt}:#{code}")
    |> Base.encode16(case: :lower)
  end

  defp utc_now do
    DateTime.utc_now() |> DateTime.truncate(:second)
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
