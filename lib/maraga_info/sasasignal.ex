defmodule MaragaInfo.Sasasignal do
  @moduledoc """
  Thin client for SasaSignal's bulk SMS campaign API.

  It authenticates with the configured email/password pair, then uploads a CSV
  of recipients to start a bulk SMS campaign.
  """

  @auth_endpoint "https://sasasignal.com/api/v1/authenticate"
  @campaign_endpoint "https://sasasignal.com/api/v1/sms/bulk/campaign/start"

  @type recipient :: String.t() | %{required(:phone) => String.t(), optional(:message) => String.t()}

  @doc """
  Authenticates against SasaSignal using either explicit credentials or the
  `SASASIGNAL_EMAIL` and `SASASIGNAL_PASSWORD` environment variables.
  """
  def authenticate(email \\ nil, password \\ nil) do
    with {:ok, email} <- credential(email, :email),
         {:ok, password} <- credential(password, :password),
         {:ok, response} <- post_json(@auth_endpoint, %{email: email, password: password}, auth_headers()),
         {:ok, token} <- extract_token(response.body) do
      {:ok,
       %{
         token: token,
         expires_at: extract_expiry(response.body),
         body: response.body,
         status: response.status
       }}
    end
  end

  @doc """
  Starts a bulk SMS campaign.

  A fresh authentication request is made before each campaign send.

  Required attrs:
    * `:sender_id`
    * `:message`
    * `:callback_url`
    * `:recipients` - list of phone strings or `%{phone: ...}` maps

  Optional attrs:
    * `:filename` - uploaded CSV filename, defaults to `"recipients.csv"`
  """
  def start_bulk_campaign(%{} = attrs) do
    with {:ok, payload} <- normalize_campaign_attrs(attrs),
         {:ok, %{token: token}} <- authenticate(),
         {:ok, csv} <- build_recipients_csv(payload.recipients),
         {:ok, response} <- post_multipart(payload, csv, token) do
      {:ok, response}
    end
  end

  @doc """
  Convenience wrapper for sending one SMS campaign.
  """
  def send_sms(message, recipients, opts \\ []) when is_binary(message) and is_list(recipients) do
    attrs =
      opts
      |> Enum.into(%{})
      |> Map.put(:message, message)
      |> Map.put(:recipients, recipients)

    start_bulk_campaign(attrs)
  end

  @doc """
  Sends an SMS to a single phone number.

  This authenticates first, then submits the send as a one-recipient bulk
  campaign so the integration stays on the documented SasaSignal flow.
  """
  def send_individual_sms(message, phone, opts \\ [])
      when is_binary(message) and is_binary(phone) do
    attrs =
      opts
      |> Enum.into(%{})
      |> Map.put(:message, message)
      |> Map.put(:recipients, [phone])

    start_bulk_campaign(attrs)
  end

  @doc """
  Builds the CSV file content expected by SasaSignal.

  The CSV always contains the header row `phone,message`. Per-recipient message
  values are left blank unless explicitly provided.
  """
  def build_recipients_csv(recipients) when is_list(recipients) do
    recipients
    |> Enum.map(&normalize_recipient/1)
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, recipient}, {:ok, acc} -> {:cont, {:ok, [recipient | acc]}}
      {:error, reason}, _acc -> {:halt, {:error, reason}}
    end)
    |> case do
      {:ok, []} ->
        {:error, {:invalid_payload, "recipients must contain at least one phone number"}}

      {:ok, normalized} ->
        rows =
          [["phone", "message"] | Enum.reverse(normalized)]
          |> Enum.map(&csv_row/1)

        {:ok, IO.iodata_to_binary(rows)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def build_recipients_csv(_),
    do: {:error, {:invalid_payload, "recipients must be a list"}}

  defp normalize_campaign_attrs(attrs) do
    with {:ok, sender_id} <-
           required_value(fetch_any(attrs, [:sender_id, "sender_id"]), "SASASIGNAL_SENDER_ID", "sender_id"),
         {:ok, message} <- normalize_string(fetch_any(attrs, [:message, "message"]), "message"),
         {:ok, callback_url} <-
           required_value(
             fetch_any(attrs, [:callback_url, "callback_url"]),
             "SASASIGNAL_CALLBACK_URL",
             "callback_url"
           ),
         {:ok, recipients} <-
           normalize_recipients(fetch_any(attrs, [:recipients, "recipients"])) do
      {:ok,
       %{
         sender_id: sender_id,
         message: message,
         callback_url: callback_url,
         recipients: recipients,
         filename:
           normalize_optional_string(fetch_any(attrs, [:filename, "filename"])) || "recipients.csv"
       }}
    end
  end

  defp normalize_recipients(recipients) when is_list(recipients), do: {:ok, recipients}

  defp normalize_recipients(_),
    do: {:error, {:invalid_payload, "recipients must be a list"}}

  defp post_multipart(payload, csv, token) do
    boundary = multipart_boundary()

    body =
      multipart_body(boundary, [
        {:field, "sender_id", payload.sender_id},
        {:field, "message", payload.message},
        {:field, "callback_url", payload.callback_url},
        {:file, "recipients_csv", payload.filename, "text/csv", csv}
      ])

    headers = [
      {"authorization", "Bearer " <> token},
      {"content-type", "multipart/form-data; boundary=" <> boundary},
      {"accept", "application/json"}
    ]

    request = Finch.build(:post, @campaign_endpoint, headers, body)

    case Finch.request(request, MaragaInfo.Finch) do
      {:ok, %Finch.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, %{status: status, body: decode_body(body)}}

      {:ok, %Finch.Response{status: status, body: body}} ->
        {:error, {:sasasignal_error, status, decode_body(body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp post_json(url, payload, headers) do
    request = Finch.build(:post, url, headers, Jason.encode!(payload))

    case Finch.request(request, MaragaInfo.Finch) do
      {:ok, %Finch.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, %{status: status, body: decode_body(body)}}

      {:ok, %Finch.Response{status: status, body: body}} ->
        {:error, {:sasasignal_error, status, decode_body(body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp auth_headers do
    [
      {"content-type", "application/json"},
      {"accept", "application/json"}
    ]
  end

  defp credential(nil, :email), do: env_value("SASASIGNAL_EMAIL", :missing_email)
  defp credential(nil, :password), do: env_value("SASASIGNAL_PASSWORD", :missing_password)
  defp credential(value, field), do: normalize_string(value, Atom.to_string(field))

  defp required_value(nil, env_name, field), do: env_value(env_name, {:invalid_payload, "#{field} is required"})
  defp required_value(value, _env_name, field), do: normalize_string(value, field)

  defp env_value(name, error_atom) do
    case System.get_env(name) do
      nil -> {:error, error_atom}
      "" -> {:error, error_atom}
      value -> {:ok, String.trim(value)}
    end
  end

  defp extract_token(%{} = body) do
    case find_first_value(body, [
           ["token"],
           ["api_token"],
           ["access_token"],
           ["data", "token"],
           ["data", "api_token"],
           ["data", "access_token"]
         ]) do
      nil -> {:error, {:invalid_response, "token not found in authentication response"}}
      token -> {:ok, token}
    end
  end

  defp extract_token(_body),
    do: {:error, {:invalid_response, "authentication response was not JSON"}}

  defp extract_expiry(%{} = body) do
    find_first_value(body, [
      ["expires_at"],
      ["expiry"],
      ["expires_in"],
      ["data", "expires_at"],
      ["data", "expiry"],
      ["data", "expires_in"]
    ])
  end

  defp extract_expiry(_body), do: nil

  defp find_first_value(map, key_paths) do
    Enum.find_value(key_paths, fn path -> get_in(map, path) end)
  end

  defp normalize_recipient(phone) when is_binary(phone) do
    with {:ok, normalized_phone} <- normalize_string(phone, "recipient.phone") do
      {:ok, [normalized_phone, ""]}
    end
  end

  defp normalize_recipient(%{} = recipient) do
    with {:ok, phone} <- normalize_string(fetch_any(recipient, [:phone, "phone"]), "recipient.phone") do
      message = normalize_optional_string(fetch_any(recipient, [:message, "message"])) || ""
      {:ok, [phone, message]}
    end
  end

  defp normalize_recipient(_),
    do: {:error, {:invalid_payload, "each recipient must be a phone string or map"}}

  defp multipart_boundary do
    "maraga-info-sasasignal-" <> Integer.to_string(System.unique_integer([:positive]))
  end

  defp multipart_body(boundary, parts) do
    closing = ["--", boundary, "--", "\r\n"]

    [Enum.map(parts, &multipart_part(boundary, &1)), closing]
    |> IO.iodata_to_binary()
  end

  defp multipart_part(boundary, {:field, name, value}) do
    [
      "--",
      boundary,
      "\r\n",
      "Content-Disposition: form-data; name=\"",
      name,
      "\"\r\n\r\n",
      value,
      "\r\n"
    ]
  end

  defp multipart_part(boundary, {:file, name, filename, content_type, content}) do
    [
      "--",
      boundary,
      "\r\n",
      "Content-Disposition: form-data; name=\"",
      name,
      "\"; filename=\"",
      filename,
      "\"\r\n",
      "Content-Type: ",
      content_type,
      "\r\n\r\n",
      content,
      "\r\n"
    ]
  end

  defp csv_row(values) do
    [
      Enum.map_join(values, ",", &csv_escape/1),
      "\n"
    ]
  end

  defp csv_escape(value) when is_binary(value) do
    escaped = String.replace(value, "\"", "\"\"")
    "\"" <> escaped <> "\""
  end

  defp decode_body(nil), do: nil
  defp decode_body(""), do: nil

  defp decode_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> decoded
      {:error, _} -> body
    end
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
end
