defmodule MaragaInfo.Campaigns.NewsletterBuilder do
  @moduledoc """
  Assembles a complete email-safe HTML document from a list of content sections.

  The UKATIBA masthead (green header + gold accent bar) and the footer (social
  icons + legal / unsubscribe block) are always included. The dynamic sections
  are rendered between them.

  Supported section types:
    - "greeting"   — eyebrow italic text + h1 headline + greeting line
    - "text"       — body paragraph
    - "highlights" — green-bordered bullet-point box
    - "cta"        — centred gold CTA button with optional subtext
    - "image"      — full-width image, optionally linked
    - "signature"  — closing signature block with name and tagline
  """

  @social_links [
    %{name: "x", href: "https://x.com/dkmaraga", label: "X"},
    %{name: "instagram", href: "https://www.instagram.com/maraga2027", label: "Instagram"},
    %{name: "youtube", href: "https://www.youtube.com/@dkmaraga", label: "YouTube"},
    %{name: "facebook", href: "https://www.facebook.com/Maraga2027", label: "Facebook"},
    %{name: "tiktok", href: "https://www.tiktok.com/@maraga2027", label: "TikTok"}
  ]

  @doc """
  Builds the complete HTML string from a list of section maps.

  Options:
    - `:preheader` — hidden preview text (shown in inbox before email is opened)
  """
  def build_html(sections, opts \\ []) when is_list(sections) do
    preheader = Keyword.get(opts, :preheader, "") || ""
    date = Keyword.get(opts, :date, nil)
    sections_html = sections |> Enum.map(&render_section/1) |> Enum.join("\n")
    wrap(sections_html, preheader, date)
  end

  # ---------- section renderers ----------

  defp render_section(%{"type" => "greeting"} = s) do
    eyebrow = Map.get(s, "eyebrow", "")
    title = Map.get(s, "title", "")
    greeting = Map.get(s, "greeting", "Hello {{first_name}},")

    eyebrow_html =
      if eyebrow != "" do
        ~s(<p class="serif-font" style="margin:0 0 8px 0;font-style:italic;font-size:17px;color:#ceb04e;">#{escape(eyebrow)}</p>)
      else
        ""
      end

    """
    <tr>
      <td class="px" style="padding:34px 44px 0 44px">
        #{eyebrow_html}
        <h1 class="head-font title" style="margin:0;font-size:34px;line-height:40px;letter-spacing:0.5px;font-weight:700;color:#222222;">#{escape(title)}</h1>
        <p class="body-font" style="margin:22px 0 0 0;font-size:16px;line-height:26px;color:#333333;">#{greeting}</p>
      </td>
    </tr>
    """
  end

  defp render_section(%{"type" => "text"} = s) do
    body = Map.get(s, "body", "")

    """
    <tr>
      <td class="px body-font" style="padding:14px 44px 0 44px;font-size:18px;line-height:31px;color:#444444;">
        #{text_body_html(body)}
      </td>
    </tr>
    """
  end

  defp render_section(%{"type" => "highlights"} = s) do
    label = Map.get(s, "label", "Highlights this week")
    items = s |> Map.get("items", []) |> Enum.reject(&(&1 == ""))

    items_html =
      items
      |> Enum.map(fn item ->
        """
        <tr>
          <td valign="top" width="20" style="font-family:Arial,sans-serif;font-size:14px;color:#d61f26;line-height:22px;">&#10003;</td>
          <td class="body-font" style="font-size:14px;line-height:21px;color:#444444;padding-bottom:9px;">#{escape(item)}</td>
        </tr>
        """
      end)
      |> Enum.join("\n")

    """
    <tr>
      <td class="px" style="padding:24px 44px 0 44px">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
          style="background-color:#f1f6f1;border-radius:14px;border-left:4px solid #ceb04e;">
          <tr>
            <td style="padding:15px 18px">
              <p class="head-font" style="margin:0 0 10px 0;font-size:12px;letter-spacing:2px;text-transform:uppercase;color:#026631;font-weight:600;">#{escape(label)}</p>
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                #{items_html}
              </table>
            </td>
          </tr>
        </table>
      </td>
    </tr>
    """
  end

  defp render_section(%{"type" => "cta"} = s) do
    url = s |> Map.get("url", "#") |> email_url() |> escape_attr()
    label = Map.get(s, "label", "Learn More")
    subtext = Map.get(s, "subtext", "")

    button_color =
      s |> Map.get("button_color", "#ceb04e") |> non_empty("#ceb04e") |> escape_attr()

    text_color = s |> Map.get("text_color", "#026631") |> non_empty("#026631") |> escape_attr()

    subtext_html =
      if subtext != "" do
        ~s(<p class="body-font" style="margin:14px 0 0 0;font-size:13px;line-height:20px;color:#888888;">#{escape(subtext)}</p>)
      else
        ""
      end

    """
    <tr>
      <td class="px" align="center" style="padding:30px 44px 6px 44px">
        <a href="#{url}" target="_blank" class="head-font"
          style="display:inline-block;background-color:#{button_color};color:#{text_color};font-size:14px;font-weight:700;letter-spacing:2px;text-transform:uppercase;padding:16px 38px;border-radius:999px;">
          #{escape(label)}
        </a>
        #{subtext_html}
      </td>
    </tr>
    """
  end

  defp render_section(%{"type" => "image"} = s) do
    url = s |> Map.get("url", "") |> email_url() |> escape_attr()
    alt = Map.get(s, "alt", "") |> escape_attr()
    link_url = s |> Map.get("link_url", "") |> email_url()

    img =
      ~s(<img src="#{url}" width="600" alt="#{alt}" style="display:block;width:100%;max-width:600px;height:auto;" />)

    inner =
      if link_url != "",
        do: ~s(<a href="#{escape_attr(link_url)}" target="_blank">#{img}</a>),
        else: img

    """
    <tr>
      <td style="padding:22px 0">#{inner}</td>
    </tr>
    """
  end

  defp render_section(%{"type" => "signature"} = s) do
    salutation = Map.get(s, "salutation", "With gratitude,")
    name = Map.get(s, "name", "The Maraga 2027 Team")
    tagline = Map.get(s, "tagline", "Integrity · Justice · Service")

    """
    <tr>
      <td class="px" style="padding:24px 44px 0 44px">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
          style="border-top:1px solid #ececec">
          <tr><td style="height:22px;font-size:0">&nbsp;</td></tr>
          <tr>
            <td class="body-font" style="font-size:16px;line-height:24px;color:#444444;">
              #{escape(salutation)}<br />
              <span class="serif-font" style="font-size:22px;font-style:italic;color:#026631;">#{escape(name)}</span><br />
              <span class="head-font" style="font-size:12px;letter-spacing:2px;text-transform:uppercase;color:#ceb04e;">#{escape(tagline)}</span>
            </td>
          </tr>
        </table>
      </td>
    </tr>
    """
  end

  defp render_section(_unknown), do: ""

  # ---------- HTML helpers ----------

  # Body text authored in the rich editor is stored as HTML; sanitise it (same
  # whitelist as post bodies) and embed it as-is so formatting, links and lists
  # survive. Legacy/plain-text bodies keep the original single-paragraph output.
  defp text_body_html(body) when is_binary(body) do
    if Regex.match?(~r|</?[a-zA-Z][^>]*>|, body) do
      MaragaInfoWeb.RichText.sanitize_email(body)
    else
      ~s(<p style="margin:0;">#{escape(body)}</p>)
    end
  end

  defp text_body_html(_), do: ""

  # Absolute URL for the Maraga '27 masthead logo. Emails require absolute image
  # URLs, so we prepend the endpoint host to the static asset path.
  defp logo_url, do: "https://davidmaraga.info" <> "/images/logo.png"

  defp non_empty(nil, default), do: default
  defp non_empty("", default), do: default
  defp non_empty(value, _default), do: value

  defp email_url(nil), do: ""

  defp email_url(url) when is_binary(url) do
    url = String.trim(url)

    if String.starts_with?(url, "/"),
      do: MaragaInfoWeb.Seo.absolute_url(url),
      else: url
  end

  defp escape(nil), do: ""

  defp escape(str) when is_binary(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp escape_attr(nil), do: ""

  defp escape_attr(str) when is_binary(str) do
    str
    |> escape()
    |> String.replace("\"", "&quot;")
  end

  defp social_links_html do
    icons =
      @social_links
      |> Enum.map(fn link ->
        """
        <td align="center" style="padding:0 5px">
          <a href="#{escape_attr(link.href)}" target="_blank" aria-label="#{escape_attr(link.label)}"
            style="display:inline-block;width:40px;height:40px;background-color:#026631;border-radius:50%;text-align:center;color:#ffffff;text-decoration:none;line-height:40px;">
            <img src="#{social_icon_url(link.name)}" width="#{social_icon_size(link.name)}" height="#{social_icon_size(link.name)}" alt="#{escape_attr(link.label)}" style="display:inline-block;width:#{social_icon_size(link.name)}px;height:#{social_icon_size(link.name)}px;margin-top:#{social_icon_margin(link.name)}px;border:0;outline:none;text-decoration:none;vertical-align:top;" />
          </a>
        </td>
        """
      end)
      |> Enum.join("\n")

    """
    <table role="presentation" cellpadding="0" cellspacing="0" border="0">
      <tr>
        #{icons}
      </tr>
    </table>
    """
  end

  defp social_icon_url(name), do: "https://davidmaraga.info/images/social/#{name}.png"

  defp social_icon_size("x"), do: 17
  defp social_icon_size("youtube"), do: 19
  defp social_icon_size(_name), do: 18

  defp social_icon_margin("youtube"), do: 10
  defp social_icon_margin(_name), do: 11

  # ---------- static wrapper ----------

  defp wrap(sections_html, preheader, date) do
    date_row =
      if date && date != "" do
        ~s(<tr><td class="px" align="right" style="padding:10px 44px 0 44px"><p class="body-font" style="margin:0;font-size:14px;color:#444444;">#{date}</p></td></tr>)
      else
        ""
      end

    """
    <!doctype html>
    <html lang="en" xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <meta http-equiv="X-UA-Compatible" content="IE=edge" />
      <meta name="color-scheme" content="light only" />
      <meta name="supported-color-schemes" content="light only" />
      <title>David Maraga Campaign — Newsletter</title>
      <!--[if mso]><noscript><xml><o:OfficeDocumentSettings><o:PixelsPerInch>96</o:PixelsPerInch></o:OfficeDocumentSettings></xml></noscript><![endif]-->
      <link href="https://fonts.googleapis.com/css2?family=Lato:ital,wght@0,400;0,700;0,900;1,400&family=Oswald:wght@400;500;600;700&family=Playfair+Display:ital,wght@0,500;1,500&display=swap" rel="stylesheet" />
      <link href="https://fonts.cdnfonts.com/css/calfine" rel="stylesheet" />
      <style>
        @font-face{font-family:"Calfine";src:url("https://fonts.cdnfonts.com/s/87534/Calfine.woff") format("woff");font-weight:normal;font-style:normal;}
        body,table,td,a{-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;}
        table,td{mso-table-lspace:0pt;mso-table-rspace:0pt;}
        img{-ms-interpolation-mode:bicubic;border:0;height:auto;line-height:100%;outline:none;text-decoration:none;}
        body{margin:0;padding:0;width:100%!important;height:100%!important;}
        a{text-decoration:none;}
        .head-font{font-family:"Oswald","Arial Narrow",Arial,sans-serif;}
        .body-font{font-family:"Lato",Arial,Helvetica,sans-serif;}
        .serif-font{font-family:"Playfair Display",Georgia,"Times New Roman",serif;}
        .calfine-font{font-family:"Calfine","Playfair Display",Georgia,"Times New Roman",serif;}
        @media screen and (max-width:620px){
          .container{width:100%!important;}
          .px{padding-left:22px!important;padding-right:22px!important;}
          .title{font-size:28px!important;line-height:34px!important;}
          .stack{display:block!important;width:100%!important;}
          .footer-col{display:block!important;width:100%!important;text-align:center!important;}
          .footer-contact{padding-top:18px!important;}
          .footer-social table{margin:0 auto!important;}
        }
      </style>
    </head>
    <body class="body-font" style="margin:0;padding:0;background-color:#eef2ee;background:radial-gradient(circle at top,rgba(208,178,22,0.1),transparent 30%),linear-gradient(180deg,#ffffff 0%,#f1f6f1 100%);">

      <div style="display:none;max-height:0;overflow:hidden;mso-hide:all;font-size:1px;line-height:1px;color:#f1f6f1;opacity:0;">#{preheader}</div>

      <center style="width:100%;background-color:#eef2ee;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
          <tr>
            <td align="center" style="padding:24px 12px">

              <!-- MAIN CARD -->
              <table role="presentation" class="container" width="600" cellpadding="0" cellspacing="0" border="0"
                style="width:600px;max-width:600px;background-color:#ffffff;border-radius:18px;overflow:hidden;box-shadow:0 18px 50px rgba(2,102,49,0.16);">

                <!-- MASTHEAD -->
                <tr>
                  <td align="center" style="background-color:#ffffff;padding:28px 24px 22px 24px">
                    <img src="#{logo_url()}" alt="Maraga '27" width="210"
                      style="display:block;width:210px;max-width:60%;height:auto;border:0;outline:none;text-decoration:none;" />
                  </td>
                </tr>

                <!-- GOLD ACCENT BAR -->
                <tr>
                  <td style="height:4px;background:linear-gradient(90deg,#ceb04e 0%,#026631 50%,#d61f26 100%);font-size:0;line-height:0;">&nbsp;</td>
                </tr>

                <!-- DYNAMIC SECTIONS -->
                #{sections_html}

                #{date_row}
                <tr>
                  <td class="px" style="padding:24px 44px 0 44px">
                    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                      <tr>
                        <td class="footer-col footer-social" valign="middle" align="left" style="width:44%">
                          <p class="head-font" style="margin:0 0 12px 0;font-size:12px;letter-spacing:2px;text-transform:uppercase;color:#026631;font-weight:700;">Connect with us</p>
                          #{social_links_html()}
                        </td>
                        <td class="footer-col footer-contact" valign="middle" align="right" style="width:56%">
                          <p class="head-font" style="margin:0 0 2px 0;font-size:11px;font-weight:600;color:#026631;letter-spacing:0.3px;line-height:16px;"><span style="color:#026631;">&#9679;</span> David Maraga Campaign Headquarters</p>
                          <p class="body-font" style="margin:0 0 5px 12px;font-size:11px;color:#555555;line-height:15px;"> Off Vihiga Rd, Kileleshwa, Nairobi</p>
                          <p class="body-font" style="margin:0 0 1px 0;font-size:11px;color:#555555;line-height:16px;"><span style="color:#026631;">&#9679;</span> +254 746 900 027</p>
                          <p class="body-font" style="margin:0;font-size:11px;line-height:16px;"><a href="https://davidmaraga.info/" target="_blank" style="color:#026631;text-decoration:none;"><span style="color:#026631;">&#9679;</span> davidMaraga.info</a></p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td class="px" style="padding:16px 44px 0 44px">
                    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                      <tr><td style="height:2px;background-color:#026631;font-size:0;line-height:0;">&nbsp;</td></tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td align="center" class="px" style="padding:22px 44px 22px 44px;border-top:1px solid #edf0ed;">
                    <p class="body-font" style="margin:0;font-size:11px;line-height:18px;color:#7b8388;">
                      You are receiving this email because you subscribed to updates from David Maraga Campaign. &copy; 2026 David Maraga Campaign. Integrity, justice and service for Kenya. All rights reserved.<br />
                      <a href="#" style="color:#7b8388;text-decoration:underline;">Unsubscribe</a>
                      &nbsp;|&nbsp;
                      <a href="#" style="color:#7b8388;text-decoration:underline;">Update preferences</a>
                      &nbsp;|&nbsp;
                      <a href="#" style="color:#7b8388;text-decoration:underline;">View in browser</a>
                    </p>
                  </td>
                </tr>

            </table>
            <!-- /MAIN CARD -->

            </td>
          </tr>
        </table>
      </center>

    </body>
    </html>
    """
  end
end
