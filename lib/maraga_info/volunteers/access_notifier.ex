defmodule MaragaInfo.Volunteers.AccessNotifier do
  @moduledoc """
  Sends short-lived access codes for the volunteer database.
  """
  import Swoosh.Email

  alias MaragaInfo.Mailer

  def deliver_access_code(email, code) when is_binary(email) and is_binary(code) do
    {from_name, from_email} =
      Application.get_env(
        :maraga_info,
        :mail_from,
        {"David Maraga Campaign", "no-reply@davidmaraga.info"}
      )

    message =
      new()
      |> to(email)
      |> from({from_name, from_email})
      |> subject("Your volunteer access code")
      |> text_body("""
      Your volunteer access code is #{code}.

      This code expires in 2 minutes. If you did not request access to the volunteer database, you can ignore this email.
      """)

    with {:ok, _metadata} <- Mailer.deliver(message) do
      {:ok, message}
    end
  end
end
