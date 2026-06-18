defmodule MaragaInfoWeb.VideoEmbed do
  @moduledoc """
  Converts video share/watch URLs (YouTube, Vimeo) into their player `embed`
  URLs so they can be shown inline through an `<iframe>`.

  Returns `nil` for anything that is not a recognised embeddable provider,
  letting callers fall back to a plain link or a native `<video>` tag for
  direct file URLs.
  """

  @youtube ~r<(?:youtube\.com/(?:watch\?(?:.*&)?v=|embed/|shorts/|live/|v/)|youtu\.be/)([\w-]{11})>
  @vimeo ~r<vimeo\.com/(?:video/)?(\d+)>

  @doc """
  Returns the iframe `src` for a known provider URL, or `nil` otherwise.

      iex> MaragaInfoWeb.VideoEmbed.embed_src("https://www.youtube.com/watch?v=XAZy5xHF9i0")
      "https://www.youtube.com/embed/XAZy5xHF9i0"
  """
  def embed_src(url) when is_binary(url) do
    url = String.trim(url)
    youtube_embed(url) || vimeo_embed(url)
  end

  def embed_src(_), do: nil

  @doc "True when the URL points at a provider we can embed via an iframe."
  def embeddable?(url), do: embed_src(url) != nil

  defp youtube_embed(url) do
    case Regex.run(@youtube, url) do
      [_, id] -> "https://www.youtube.com/embed/#{id}"
      _ -> nil
    end
  end

  defp vimeo_embed(url) do
    case Regex.run(@vimeo, url) do
      [_, id] -> "https://player.vimeo.com/video/#{id}"
      _ -> nil
    end
  end
end
