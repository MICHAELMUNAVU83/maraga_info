defmodule MaragaInfo.Campaigns.CampaignEmail do
  @moduledoc """
  Turns an `EmailCampaign` plus a recipient into a branded Swoosh email.

  The HTML wrapper mirrors the look of the public site (Playfair Display
  headings, Lato body, the campaign green/gold palette) using table-based,
  inline-styled markup so it renders consistently across email clients.
  """
  import Swoosh.Email

  alias MaragaInfo.Campaigns.EmailCampaign
  alias Phoenix.HTML

  @green "#32673B"
  @gold "#CEB04E"
  @ink "#222222"
  @muted "#5b6168"

  @doc """
  Builds a ready-to-deliver `Swoosh.Email` for one recipient.

  `recipient` is a map with `:email` and optional `:name`.
  """
  def build(%EmailCampaign{} = campaign, recipient, from) do
    new()
    |> to({recipient_name(recipient), recipient.email})
    |> from(from)
    |> subject(campaign.subject)
    |> maybe_reply_to(campaign.reply_to)
    |> html_body(render_html(campaign, recipient))
    |> text_body(render_text(campaign, recipient))
  end

  defp maybe_reply_to(email, nil), do: email
  defp maybe_reply_to(email, ""), do: email
  defp maybe_reply_to(email, reply_to), do: reply_to(email, reply_to)

  @doc "Renders the full branded HTML document for a recipient (used for preview too)."
  def render_html(%EmailCampaign{} = campaign, recipient) do
    body_html =
      campaign.body
      |> personalize(recipient)
      |> body_to_html()

    signature = signature_html(campaign)
    preheader = campaign.preheader || ""
    logo = logo_url()

    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
      <title>#{escape(campaign.subject)}</title>
    </head>
    <body style="margin:0; padding:0; background-color:#f0f4ff; -webkit-text-size-adjust:100%;">
      <div style="display:none; max-height:0; overflow:hidden; opacity:0; color:#f0f4ff; font-size:1px; line-height:1px;">
        #{escape(preheader)}
      </div>
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f0f4ff;">
        <tr>
          <td align="center" style="padding:32px 16px;">
            <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="width:600px; max-width:600px; background-color:#ffffff; border-radius:16px; overflow:hidden; box-shadow:0 12px 30px rgba(15,23,42,0.08);">
              <tr>
                <td style="background-color:#{@green}; padding:28px 40px;" align="center">
                  #{logo_block(logo)}
                </td>
              </tr>
              <tr>
                <td style="height:4px; background-color:#{@gold}; line-height:4px; font-size:4px;">&nbsp;</td>
              </tr>
              <tr>
                <td style="padding:40px 40px 8px 40px; font-family:'Playfair Display', Georgia, serif; color:#{@ink};">
                  <h1 style="margin:0; font-size:26px; line-height:1.25; font-weight:700; color:#{@green};">
                    #{escape(campaign.subject)}
                  </h1>
                </td>
              </tr>
              <tr>
                <td style="padding:16px 40px 8px 40px; font-family:'Lato', Helvetica, Arial, sans-serif; color:#{@ink}; font-size:16px; line-height:1.7;">
                  #{body_html}
                </td>
              </tr>
              <tr>
                <td style="padding:8px 40px 40px 40px; font-family:'Lato', Helvetica, Arial, sans-serif; color:#{@ink}; font-size:16px; line-height:1.6;">
                  #{signature}
                </td>
              </tr>
              <tr>
                <td style="background-color:#0f172a; padding:28px 40px; font-family:'Lato', Helvetica, Arial, sans-serif;">
                  <p style="margin:0 0 6px 0; color:#ffffff; font-size:14px; font-weight:700;">David Maraga Campaign</p>
                  <p style="margin:0; color:#94a3b8; font-size:12px; line-height:1.6;">
                    You are receiving this because you joined the movement.<br />
                    Constitutionalism &middot; Human dignity &middot; Economic renewal
                  </p>
                </td>
              </tr>
            </table>
            <p style="margin:18px 0 0 0; font-family:'Lato', Helvetica, Arial, sans-serif; color:#94a3b8; font-size:12px;">
              &copy; #{Date.utc_today().year} David Maraga Campaign. Nairobi, Kenya.
            </p>
          </td>
        </tr>
      </table>
    </body>
    </html>
    """
  end

  @doc "Plain-text fallback for clients that don't render HTML."
  def render_text(%EmailCampaign{} = campaign, recipient) do
    body = personalize(campaign.body, recipient)

    signature =
      [campaign.sender_name, campaign.sender_title]
      |> Enum.reject(&blank?/1)
      |> Enum.join("\n")

    [campaign.subject, "", body, "", signature, "", "— David Maraga Campaign"]
    |> Enum.join("\n")
    |> String.trim()
  end

  @doc "Replaces `{{name}}` / `{{first_name}}` placeholders for a recipient."
  def personalize(text, recipient) when is_binary(text) do
    name = recipient_name(recipient)
    first = name |> String.split(" ", parts: 2) |> List.first()

    text
    |> String.replace(~r/\{\{\s*name\s*\}\}/i, name)
    |> String.replace(~r/\{\{\s*first_name\s*\}\}/i, first)
  end

  defp recipient_name(%{name: name}) when is_binary(name) do
    case String.trim(name) do
      "" -> "Friend"
      trimmed -> trimmed
    end
  end

  defp recipient_name(_recipient), do: "Friend"

  # Splits the body on blank lines into paragraphs, escapes each, and renders
  # "LABEL: value" lines (DATE:, TIME:, VENUE: ...) as an accented detail block.
  defp body_to_html(body) do
    body
    |> String.split(~r/\n\s*\n/, trim: true)
    |> Enum.map_join("\n", &paragraph_html/1)
  end

  defp paragraph_html(paragraph) do
    lines = String.split(paragraph, "\n")

    if Enum.all?(lines, &label_line?/1) and length(lines) > 0 do
      details_block(lines)
    else
      inner = Enum.map_join(lines, "<br />", &escape/1)

      ~s(<p style="margin:0 0 18px 0;">#{inner}</p>)
    end
  end

  defp label_line?(line), do: Regex.match?(~r/^\s*[A-Z][A-Z ]{1,20}:\s*\S/, line)

  defp details_block(lines) do
    rows =
      Enum.map_join(lines, "", fn line ->
        [label, value] = String.split(line, ":", parts: 2)

        ~s(<tr><td style="padding:4px 16px 4px 0; font-weight:700; color:#{@green}; white-space:nowrap; vertical-align:top;">#{escape(String.trim(label))}</td><td style="padding:4px 0; color:#{@ink}; vertical-align:top;">#{escape(String.trim(value))}</td></tr>)
      end)

    ~s(<table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 0 18px 0; padding:16px 20px; background-color:#f0f4ff; border-left:4px solid #{@gold}; border-radius:8px; font-size:15px; line-height:1.5;">#{rows}</table>)
  end

  defp signature_html(campaign) do
    title =
      if blank?(campaign.sender_title),
        do: "",
        else: ~s(<br /><span style="color:#{@muted};">#{escape(campaign.sender_title)}</span>)

    ~s(<p style="margin:0;">Warm regards,</p><p style="margin:6px 0 0 0; font-weight:700; color:#{@ink};">#{escape(campaign.sender_name)}#{title}</p>)
  end

  defp logo_block(nil) do
    ~s(<span style="font-family:'Playfair Display', Georgia, serif; color:#ffffff; font-size:24px; font-weight:700; letter-spacing:0.5px;">David Maraga</span>)
  end

  defp logo_block(url) do
    ~s(<img src="#{url}" alt="David Maraga" height="40" style="height:40px; display:block; border:0;" />)
  end

  defp logo_url do
    MaragaInfoWeb.Endpoint.url() <> "/images/logo.png"
  rescue
    _ -> nil
  end

  defp blank?(nil), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_), do: false

  defp escape(value) do
    value
    |> to_string()
    |> HTML.html_escape()
    |> HTML.safe_to_string()
  end
end
