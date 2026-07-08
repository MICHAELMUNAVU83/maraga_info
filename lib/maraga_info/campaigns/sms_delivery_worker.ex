defmodule MaragaInfo.Campaigns.SmsDeliveryWorker do
  @moduledoc """
  Sends a single queued SMS delivery with conservative retry backoff so the
  provider is not overwhelmed during campaign bursts.
  """
  use Oban.Worker, queue: :sms, max_attempts: 5

  alias MaragaInfo.Campaigns

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"delivery_id" => delivery_id},
        attempt: attempt,
        max_attempts: max
      }) do
    Campaigns.deliver_sms(delivery_id, last_attempt?: attempt >= max)
  end

  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}) do
    trunc(:math.pow(3, attempt) * 20)
  end
end
