defmodule MaragaInfo.Campaigns.DeliveryWorker do
  @moduledoc """
  Sends a single campaign email. One job per recipient keeps the blast
  resilient: a failed address retries on its own without holding up the rest.
  """
  use Oban.Worker, queue: :mailers, max_attempts: 3

  alias MaragaInfo.Campaigns

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"delivery_id" => delivery_id},
        attempt: attempt,
        max_attempts: max
      }) do
    Campaigns.deliver(delivery_id, last_attempt?: attempt >= max)
  end

  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}) do
    # 30s, 2m, 8m – give transient SMTP/provider issues time to clear.
    trunc(:math.pow(4, attempt) * 30)
  end
end
