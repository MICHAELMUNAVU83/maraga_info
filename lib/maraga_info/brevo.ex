defmodule MaragaInfo.Brevo do
  @moduledoc """
  Thin client for Brevo's transactional email API.

  This wraps `POST https://api.brevo.com/v3/smtp/email` and accepts the same
  data as the curl example, but in idiomatic Elixir shapes.

  Example:

      MaragaInfo.Brevo.send_email(%{
        sender: %{name: "Alex from Brevo", email: "hello@brevo.com"},
        to: [%{email: "johndoe@example.com", name: "John Doe"}],
        subject: "Hello from Brevo!",
        html_content: "<html><head></head><body><p>Hello,</p><p>This is my first transactional email sent from Brevo.</p></body></html>"
      })
  """

  @endpoint "https://api.brevo.com/v3/smtp/email"

  @type contact :: %{required(:email) => String.t(), optional(:name) => String.t()}
  @type payload :: %{
          required(:sender) => contact(),
          required(:to) => [contact()],
          required(:subject) => String.t(),
          required(:htmlContent) => String.t()
        }

  @doc """
  Sends one transactional email through Brevo.

  Accepts either a map payload or the convenience form:

      send_email(sender, recipients, subject, html_content)
  """
  def send_email(sender, recipients, subject, html_content)
      when is_map(sender) and is_list(recipients) and is_binary(subject) and
             is_binary(html_content) do
    send_email(%{
      sender: sender,
      to: recipients,
      subject: subject,
      html_content: html_content
    })
  end

  def send_email(%{} = attrs) do
    with {:ok, api_key} <- api_key(),
         {:ok, payload} <- build_payload(attrs),
         {:ok, response} <- post(payload, api_key) do
      {:ok, response}
    end
  end

  @doc """
  Builds the JSON payload sent to Brevo.

  This is public so it can be reused in tests or higher-level calling code.
  """
  def build_payload(%{} = attrs) do
    with {:ok, sender} <- normalize_contact(fetch_any(attrs, [:sender, "sender"]), "sender"),
         {:ok, recipients} <- normalize_recipients(fetch_any(attrs, [:to, "to"])),
         {:ok, subject} <- normalize_string(fetch_any(attrs, [:subject, "subject"]), "subject"),
         {:ok, html_content} <-
           normalize_string(fetch_any(attrs, [:html_content, "htmlContent"]), "html_content") do
      payload =
        %{
          sender: sender,
          to: recipients,
          subject: subject,
          htmlContent: html_content
        }
        |> maybe_put(
          :textContent,
          normalize_optional_string(fetch_any(attrs, [:text_content, "textContent"]))
        )

      {:ok, payload}
    end
  end

  defp post(payload, api_key) do
    request =
      Finch.build(:post, @endpoint, headers(api_key), Jason.encode!(payload))

    case Finch.request(request, MaragaInfo.Finch) do
      {:ok, %Finch.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, %{status: status, body: decode_body(body)}}

      {:ok, %Finch.Response{status: status, body: body}} ->
        {:error, {:brevo_error, status, decode_body(body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp headers(api_key) do
    [
      {"accept", "application/json"},
      {"api-key", api_key},
      {"content-type", "application/json"}
    ]
  end

  defp api_key do
    case Application.get_env(:maraga_info, :brevo_api_key) || System.get_env("BREVO_API_KEY") do
      nil -> {:error, :missing_api_key}
      "" -> {:error, :missing_api_key}
      key -> {:ok, key}
    end
  end

  defp decode_body(nil), do: nil
  defp decode_body(""), do: nil

  defp decode_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> decoded
      {:error, _} -> body
    end
  end

  defp normalize_recipients(%{} = recipient), do: normalize_recipients([recipient])

  defp normalize_recipients(recipients) when is_list(recipients) do
    recipients
    |> Enum.map(&normalize_contact(&1, "to"))
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, contact}, {:ok, acc} -> {:cont, {:ok, [contact | acc]}}
      {:error, reason}, _acc -> {:halt, {:error, reason}}
    end)
    |> case do
      {:ok, []} -> {:error, {:invalid_payload, "to must contain at least one recipient"}}
      {:ok, recipients} -> {:ok, Enum.reverse(recipients)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_recipients(_),
    do: {:error, {:invalid_payload, "to must be a list of recipients"}}

  defp normalize_contact(%{} = contact, label) do
    with {:ok, email} <- normalize_string(fetch_any(contact, [:email, "email"]), "#{label}.email") do
      contact =
        %{email: email}
        |> maybe_put(:name, normalize_optional_string(fetch_any(contact, [:name, "name"])))

      {:ok, contact}
    end
  end

  defp normalize_contact(_value, label) do
    {:error, {:invalid_payload, "#{label} must be a map with an email"}}
  end

  defp normalize_string(nil, field), do: {:error, {:invalid_payload, "#{field} is required"}}

  defp normalize_string(value, field) when is_binary(value) do
    trimmed = String.trim(value)

    if trimmed == "" do
      {:error, {:invalid_payload, "#{field} is required"}}
    else
      {:ok, trimmed}
    end
  end

  defp normalize_string(_value, field),
    do: {:error, {:invalid_payload, "#{field} must be a string"}}

  defp normalize_optional_string(nil), do: nil

  defp normalize_optional_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_optional_string(_value), do: nil

  defp fetch_any(map, keys) do
    Enum.find_value(keys, &Map.get(map, &1))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
