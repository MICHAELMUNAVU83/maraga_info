defmodule MaragaInfo.Campaigns.CampaignEmail do
  @moduledoc """
  Turns an `EmailCampaign` variant plus a recipient into a Swoosh email.

  When a campaign has `sections`, the HTML is assembled via `NewsletterBuilder`.
  Otherwise the raw `body` field is used as-is. The placeholders `{{name}}` /
  `{{first_name}}` are replaced per recipient in either path.
  """
  import Swoosh.Email

  alias MaragaInfo.Campaigns.EmailCampaign
  alias MaragaInfo.Campaigns.NewsletterBuilder

  @doc """
  Builds a ready-to-deliver `Swoosh.Email` for one recipient and variant.

  `recipient` is a map with `:email` and optional `:name`. `variant` is `"A"`
  or `"B"`. `from_email` is the configured sending address; the variant's
  `sender_name` is used as the display name.
  """
  def build(%EmailCampaign{} = campaign, variant, recipient, from_email) do
    content = variant_content(campaign, variant)

    new()
    |> to({recipient_name(recipient), recipient.email})
    |> from({content.sender_name, from_email})
    |> subject(personalize(content.subject, recipient))
    |> maybe_reply_to(campaign.reply_to)
    |> html_body(render_html(content, recipient))
    |> text_body(render_text(content, recipient))
  end

  @doc """
  Resolves the content for a variant: `"A"` uses the primary fields, `"B"` uses
  the `*_b` fields. Returns a map with `:subject`, `:sender_name`, `:body`, and
  `:sections` (sections are shared between variants).
  """
  def variant_content(%EmailCampaign{} = campaign, "B") do
    %{
      subject: campaign.subject_b,
      sender_name: campaign.sender_name_b,
      body: campaign.body_b,
      preheader: campaign.preheader,
      sections: campaign.sections || []
    }
  end

  def variant_content(%EmailCampaign{} = campaign, _a) do
    %{
      subject: campaign.subject,
      sender_name: campaign.sender_name,
      body: campaign.body,
      preheader: campaign.preheader,
      sections: campaign.sections || []
    }
  end

  @doc """
  Renders the HTML document for a recipient (used for delivery and preview).

  When the campaign has sections, builds the HTML via `NewsletterBuilder`.
  Otherwise uses the raw `body` field.
  """
  def render_html(%EmailCampaign{} = campaign, variant, recipient) when is_binary(variant) do
    render_html(variant_content(campaign, variant), recipient)
  end

  def render_html(%{sections: sections, preheader: preheader}, recipient)
      when is_list(sections) and sections != [] do
    NewsletterBuilder.build_html(sections, preheader: preheader)
    |> personalize(recipient)
  end

  def render_html(%{body: body}, recipient) do
    (body || "")
    |> personalize(recipient)
  end

  @doc "Plain-text fallback derived from the HTML body."
  def render_text(%{sections: sections} = content, recipient)
      when is_list(sections) and sections != [] do
    render_html(content, recipient) |> html_to_text()
  end

  def render_text(%{body: body}, recipient) do
    (body || "")
    |> personalize(recipient)
    |> html_to_text()
  end

  @doc "Replaces `{{name}}` / `{{first_name}}` placeholders for a recipient."
  def personalize(nil, _recipient), do: ""

  def personalize(text, recipient) when is_binary(text) do
    name = recipient_name(recipient)
    first = name |> String.split(" ", parts: 2) |> List.first()

    text
    |> String.replace(~r/\{\{\s*name\s*\}\}/i, name)
    |> String.replace(~r/\{\{\s*first_name\s*\}\}/i, first)
  end

  defp maybe_reply_to(email, nil), do: email
  defp maybe_reply_to(email, ""), do: email
  defp maybe_reply_to(email, reply_to), do: reply_to(email, reply_to)

  defp recipient_name(%{name: name}) when is_binary(name) do
    case String.trim(name) do
      "" -> "Friend"
      trimmed -> trimmed
    end
  end

  defp recipient_name(_recipient), do: "Friend"

  # Strips tags so HTML-only clients still receive readable text.
  defp html_to_text(html) do
    case Floki.parse_document(html) do
      {:ok, document} ->
        document
        |> Floki.text(sep: " ")
        |> String.replace(~r/[ \t]+/, " ")
        |> String.replace(~r/\s*\n\s*/, "\n")
        |> String.trim()

      _ ->
        html
    end
  end
end
