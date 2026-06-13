defmodule MaragaInfoWeb.Uploads do
  @moduledoc """
  Helpers for storing LiveView uploads on local disk and returning the public
  URL that can be served by `Plug.Static` from `priv/static/uploads`.
  """

  @upload_dir Path.join(["priv", "static", "uploads"])

  @doc """
  Copies an uploaded entry into `priv/static/uploads` and returns its public
  path (e.g. `/uploads/ab12cd34.jpg`).
  """
  def store_entry(meta, entry) do
    File.mkdir_p!(@upload_dir)
    extension = extension(entry)
    filename = "#{entry.uuid}#{extension}"
    dest = Path.join(@upload_dir, filename)
    File.cp!(meta.path, dest)
    {:ok, "/uploads/#{filename}"}
  end

  defp extension(entry) do
    case Path.extname(entry.client_name) do
      "" -> ext_from_type(entry.client_type)
      ext -> String.downcase(ext)
    end
  end

  defp ext_from_type("image/png"), do: ".png"
  defp ext_from_type("image/webp"), do: ".webp"
  defp ext_from_type("image/gif"), do: ".gif"
  defp ext_from_type(_), do: ".jpg"
end
