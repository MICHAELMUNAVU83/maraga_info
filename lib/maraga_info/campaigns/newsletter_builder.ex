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
        <h1 class="head-font title" style="margin:0;font-size:34px;line-height:40px;letter-spacing:0.5px;text-transform:uppercase;font-weight:700;color:#222222;">#{escape(title)}</h1>
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
    url = Map.get(s, "url", "#") |> escape_attr()
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
    url = Map.get(s, "url", "") |> escape_attr()
    alt = Map.get(s, "alt", "") |> escape_attr()
    link_url = Map.get(s, "link_url", "")

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
            style="display:inline-block;width:40px;height:40px;background-color:#026631;border-radius:50%;text-align:center;color:#ffffff;text-decoration:none;">
            #{social_icon(link.name)}
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

  defp social_icon("facebook") do
    """
    <svg width="18" height="18" viewBox="0 0 24 24" fill="#ffffff" xmlns="http://www.w3.org/2000/svg" style="display:block;margin:11px auto 0 auto;">
      <path d="M22 12a10 10 0 1 0-11.56 9.88v-6.99H7.9V12h2.54V9.8c0-2.5 1.49-3.89 3.78-3.89 1.09 0 2.24.2 2.24.2v2.46h-1.26c-1.24 0-1.63.77-1.63 1.56V12h2.78l-.44 2.89h-2.34v6.99A10 10 0 0 0 22 12z" />
    </svg>
    """
  end

  defp social_icon("x") do
    """
    <svg width="16" height="16" viewBox="0 0 24 24" fill="#ffffff" xmlns="http://www.w3.org/2000/svg" style="display:block;margin:12px auto 0 auto;">
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24h-6.66l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
    </svg>
    """
  end

  defp social_icon("instagram") do
    """
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg" style="display:block;margin:11px auto 0 auto;">
      <rect x="2" y="2" width="20" height="20" rx="5" ry="5" />
      <path d="M16 11.37a4 4 0 1 1-7.91 1.17 4 4 0 0 1 7.91-1.17z" />
      <line x1="17.5" y1="6.5" x2="17.51" y2="6.5" />
    </svg>
    """
  end

  defp social_icon("youtube") do
    """
    <svg width="18" height="18" viewBox="0 0 24 24" fill="#ffffff" xmlns="http://www.w3.org/2000/svg" style="display:block;margin:11px auto 0 auto;">
      <path d="M23.5 6.2a3 3 0 0 0-2.1-2.12C19.53 3.5 12 3.5 12 3.5s-7.53 0-9.4.58A3 3 0 0 0 .5 6.2 31.4 31.4 0 0 0 0 12a31.4 31.4 0 0 0 .5 5.8 3 3 0 0 0 2.1 2.12c1.87.58 9.4.58 9.4.58s7.53 0 9.4-.58a3 3 0 0 0 2.1-2.12A31.4 31.4 0 0 0 24 12a31.4 31.4 0 0 0-.5-5.8ZM9.6 15.94V8.06L16.4 12 9.6 15.94Z" />
    </svg>
    """
  end

  defp social_icon("tiktok") do
    """
    <svg width="18" height="18" viewBox="0 0 24 24" fill="#ffffff" xmlns="http://www.w3.org/2000/svg" style="display:block;margin:11px auto 0 auto;">
      <path d="M16.6 5.82a4.28 4.28 0 0 1-1.05-2.82h-3.1v12.42a2.6 2.6 0 1 1-1.84-2.49V9.74a5.7 5.7 0 1 0 4.94 5.65V9.01a7.32 7.32 0 0 0 4.28 1.37V7.28a4.28 4.28 0 0 1-3.18-1.46z" />
    </svg>
    """
  end

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
                        <td valign="middle" align="left" style="width:44%">
                          <p class="head-font" style="margin:0 0 12px 0;font-size:12px;letter-spacing:2px;text-transform:uppercase;color:#026631;font-weight:700;">Connect with us</p>
                          #{social_links_html()}
                        </td>
                        <td valign="middle" align="right" style="width:56%">
                          <p class="head-font" style="margin:0 0 2px 0;font-size:11px;font-weight:600;color:#026631;letter-spacing:0.3px;line-height:16px;"><span style="color:#026631;">&#9679;</span> David Maraga Campaign Headquarters</p>
                          <p class="body-font" style="margin:0 0 5px 12px;font-size:11px;color:#555555;line-height:15px;">Kileleshwa, Nairobi</p>
                          <p class="body-font" style="margin:0 0 1px 0;font-size:11px;color:#555555;line-height:16px;"><span style="color:#026631;">&#9679;</span> +254 746 900 027</p>
                          <p class="body-font" style="margin:0;font-size:11px;line-height:16px;"><a href="https://davidmaraga.com/" target="_blank" style="color:#026631;text-decoration:none;"><span style="color:#026631;">&#9679;</span> DavidMaraga.com</a></p>
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
