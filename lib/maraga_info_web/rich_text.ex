defmodule MaragaInfoWeb.RichText do
  @moduledoc """
  Renders the small set of inline formatting markers used by the post editor
  (`**bold**`, `_italic_`, `++underline++`) into safe HTML.

  Text is HTML-escaped first so user content can never inject markup; only the
  known wrappers become tags.
  """

  @doc """
  Splits text into paragraphs on blank lines, mirroring how the editor stores
  multi-paragraph content.
  """
  def paragraphs(nil), do: []

  def paragraphs(text) when is_binary(text) do
    text
    |> String.split(~r/\n\s*\n/, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  @doc """
  Returns a `{:safe, iodata}` value with the inline markers rendered as
  `<strong>`, `<em>` and `<u>` tags.
  """
  def format_inline(text) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
    |> apply_marks()
    |> Phoenix.HTML.raw()
  end

  defp apply_marks(escaped) do
    escaped
    |> String.replace(~r/\*\*(.+?)\*\*/s, "<strong>\\1</strong>")
    |> String.replace(~r/\+\+(.+?)\+\+/s, "<u>\\1</u>")
    |> String.replace(~r/_(.+?)_/s, "<em>\\1</em>")
  end
end
