defmodule MaragaInfoWeb.RichText do
  @moduledoc """
  Renders post bodies for display and prepares stored content for the editor.

  New posts are authored in CKEditor and stored as HTML, which is sanitised
  through a strict tag/attribute whitelist before it is rendered. Older posts
  were stored with inline markers (`**bold**`, `{{color:crimson}}…{{/color}}`);
  those are still understood so existing content keeps rendering, and they are
  converted to HTML the first time such a post is opened in the editor.
  """

  # Tag => attributes kept on it. Everything else is dropped (children kept).
  @allowed_tags %{
    "p" => ["style"],
    "br" => [],
    "strong" => [],
    "b" => [],
    "em" => [],
    "i" => [],
    "u" => [],
    "s" => [],
    "strike" => [],
    "span" => ["style"],
    "mark" => ["style"],
    "h2" => ["style"],
    "h3" => ["style"],
    "h4" => ["style"],
    "ul" => [],
    "ol" => [],
    "li" => [],
    "blockquote" => [],
    "a" => ["href", "target", "rel"]
  }

  # Tags dropped together with their contents (rather than unwrapped), so their
  # raw text never leaks into the page.
  @drop_with_content ~w(script style iframe object embed svg math noscript template head title link meta)

  @doc """
  Renders a stored post body to safe HTML for display.

  HTML content is sanitised; legacy marker content is converted on the fly.
  """
  def render(text) when is_binary(text) do
    if html?(text) do
      text |> sanitize() |> Phoenix.HTML.raw()
    else
      text |> legacy_html() |> Phoenix.HTML.raw()
    end
  end

  def render(_), do: Phoenix.HTML.raw("")

  @doc """
  Returns an HTML string suitable for seeding the CKEditor instance. Legacy
  marker content is converted so authors see formatted text, not raw markers.
  """
  def to_editor_html(text) when is_binary(text) do
    if html?(text), do: sanitize(text), else: legacy_html(text)
  end

  def to_editor_html(_), do: ""

  defp html?(text), do: Regex.match?(~r|</?[a-zA-Z][^>]*>|, text)

  # ----------------------------------------------------------------------------
  # HTML sanitisation
  # ----------------------------------------------------------------------------

  defp sanitize(html) do
    case Floki.parse_fragment(html) do
      {:ok, tree} -> tree |> scrub_nodes() |> Floki.raw_html()
      _ -> ""
    end
  end

  defp scrub_nodes(nodes) when is_list(nodes), do: Enum.flat_map(nodes, &scrub_node/1)

  defp scrub_node(text) when is_binary(text), do: [text]

  defp scrub_node({tag, attrs, children}) do
    tag = String.downcase(tag)

    cond do
      tag in @drop_with_content -> []
      Map.has_key?(@allowed_tags, tag) -> [{tag, scrub_attrs(attrs, @allowed_tags[tag]), scrub_nodes(children)}]
      # Unknown but harmless tag: drop the wrapper but keep its scrubbed contents.
      true -> scrub_nodes(children)
    end
  end

  defp scrub_node(_), do: []

  defp scrub_attrs(attrs, allowed) do
    for {name, value} <- attrs,
        name = String.downcase(name),
        name in allowed,
        cleaned = clean_attr(name, value),
        cleaned != nil,
        do: {name, cleaned}
  end

  defp clean_attr("style", value), do: clean_style(value)
  defp clean_attr("href", value), do: if(safe_href?(value), do: String.trim(value))
  defp clean_attr("target", _), do: "_blank"
  defp clean_attr("rel", _), do: "noopener noreferrer"
  defp clean_attr(_, value), do: value

  # Keep only colour and alignment declarations with validated values.
  defp clean_style(value) do
    declarations =
      value
      |> String.split(";")
      |> Enum.flat_map(fn decl ->
        case String.split(decl, ":", parts: 2) do
          [prop, val] -> keep_style(String.downcase(String.trim(prop)), String.trim(val))
          _ -> []
        end
      end)

    case declarations do
      [] -> nil
      decls -> Enum.join(decls, "; ")
    end
  end

  defp keep_style(prop, val) when prop in ["color", "background-color"] do
    if safe_color?(val), do: ["#{prop}: #{val}"], else: []
  end

  defp keep_style("text-align", val) when val in ["left", "center", "right", "justify"],
    do: ["text-align: #{val}"]

  defp keep_style(_, _), do: []

  defp safe_color?(val) do
    Regex.match?(~r/^#[0-9a-fA-F]{3,8}$/, val) or
      Regex.match?(~r/^rgba?\([\d.,\s%]+\)$/i, val) or
      Regex.match?(~r/^hsla?\([\d.,\s%]+\)$/i, val) or
      Regex.match?(~r/^[a-zA-Z]+$/, val)
  end

  defp safe_href?(value) do
    v = value |> String.trim() |> String.downcase()

    String.starts_with?(v, "http://") or String.starts_with?(v, "https://") or
      String.starts_with?(v, "mailto:") or String.starts_with?(v, "/") or
      String.starts_with?(v, "#")
  end

  # ----------------------------------------------------------------------------
  # Legacy marker rendering (pre-CKEditor content)
  # ----------------------------------------------------------------------------

  @doc """
  Splits legacy text into paragraphs on blank lines. Retained for content that
  predates the HTML editor and for tests.
  """
  def paragraphs(nil), do: []

  def paragraphs(text) when is_binary(text) do
    text
    |> String.split(~r/\n\s*\n/, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  @doc """
  Renders the legacy inline markers in a single paragraph to safe HTML.
  """
  def format_inline(text) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
    |> apply_marks()
    |> Phoenix.HTML.raw()
  end

  defp legacy_html(text) do
    text
    |> paragraphs()
    |> Enum.map_join("", fn p -> "<p>" <> Phoenix.HTML.safe_to_string(format_inline(p)) <> "</p>" end)
  end

  defp apply_marks(escaped) do
    escaped
    |> replace_color()
    |> replace_highlight()
    |> replace_align()
    |> String.replace(~r/\*\*(.+?)\*\*/s, "<strong>\\1</strong>")
    |> String.replace(~r/\+\+(.+?)\+\+/s, "<u>\\1</u>")
    |> String.replace(~r/_(.+?)_/s, "<em>\\1</em>")
    |> String.replace(
      ~r/==(.+?)==/s,
      ~s(<mark class="rounded-sm bg-amber-200 px-1 text-blueink">\\1</mark>)
    )
  end

  defp replace_color(text) do
    Regex.replace(
      ~r/\{\{color:(#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3}|[a-z-]+)\}\}(.+?)\{\{\/color\}\}/s,
      text,
      fn _, color, inner -> ~s(<span#{color_attr(color)}>#{inner}</span>) end
    )
  end

  defp replace_highlight(text) do
    Regex.replace(
      ~r/\{\{highlight:(#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3}|[a-z-]+)\}\}(.+?)\{\{\/highlight\}\}/s,
      text,
      fn _, tone, inner -> ~s(<mark#{highlight_attr(tone)}>#{inner}</mark>) end
    )
  end

  defp replace_align(text) do
    Regex.replace(~r/\{\{align:([a-z]+)\}\}(.+?)\{\{\/align\}\}/s, text, fn _, align, inner ->
      ~s(<span class="block #{align_class(align)}">#{inner}</span>)
    end)
  end

  defp color_attr("crimson"), do: ~s( class="text-crimson")
  defp color_attr("blueink"), do: ~s( class="text-blueink")
  defp color_attr("gold"), do: ~s( class="text-[#d0b216]")
  defp color_attr("green"), do: ~s( class="text-[#0b7600]")
  defp color_attr("#" <> _ = hex), do: ~s( style="color: #{hex}")
  defp color_attr(_), do: ~s( class="text-current")

  defp highlight_attr("gold"), do: ~s( class="rounded-sm bg-amber-200 px-1 text-blueink")
  defp highlight_attr("blue"), do: ~s( class="rounded-sm bg-sky-100 px-1 text-blueink")

  defp highlight_attr("#" <> _ = hex),
    do: ~s( class="rounded-sm px-1" style="background-color: #{hex}")

  defp highlight_attr(_), do: ~s( class="rounded-sm bg-amber-200 px-1 text-blueink")

  defp align_class("left"), do: "text-left"
  defp align_class("center"), do: "text-center"
  defp align_class("right"), do: "text-right"
  defp align_class(_), do: "text-left"
end
