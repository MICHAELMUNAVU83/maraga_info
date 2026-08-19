defmodule MaragaInfo.Volunteers.BrevoSyncWorker do
  @moduledoc """
  Pushes a volunteer's contact details to Brevo so they land in the
  campaign's mailing list, independent of the transactional welcome email.
  """
  use Oban.Worker, queue: :mailers, max_attempts: 5

  alias MaragaInfo.Brevo
  alias MaragaInfo.Volunteers

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"volunteer_id" => volunteer_id}}) do
    volunteer_id
    |> Volunteers.get_volunteer!()
    |> sync()
  rescue
    Ecto.NoResultsError -> :ok
  end

  defp sync(volunteer) do
    attributes =
      %{}
      |> maybe_put("FIRSTNAME", volunteer.first_name || volunteer.full_name)
      |> maybe_put("LASTNAME", volunteer.last_name)
      |> maybe_put("SMS", volunteer.phone)
      |> maybe_put("COUNTY", volunteer.county)

    list_ids = brevo_list_ids()

    case Brevo.upsert_contact(volunteer.email, attributes, list_ids) do
      {:ok, _response} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp brevo_list_ids do
    :maraga_info
    |> Application.get_env(:brevo_list_ids, [])
    |> List.wrap()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
