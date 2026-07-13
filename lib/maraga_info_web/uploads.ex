defmodule MaragaInfoWeb.Uploads do
  @moduledoc """
  Helpers for storing LiveView uploads on local disk and returning the public
  URL that can be served by `Plug.Static` from `priv/static/uploads`.
  """

  @upload_dir Path.join(["priv", "static", "uploads"])

  @doc """
  Copies an uploaded entry into `priv/static/uploads` and returns its public
  path (e.g. `/uploads/ab12cd34.jpg`).

  Image entries can be resized while retaining their aspect ratio by passing
  `resize: {max_width, max_height}`. Resizing also applies EXIF orientation and
  removes metadata that is not needed when serving the image on the web.
  """
  def store_entry(meta, entry, opts \\ []) do
    File.mkdir_p!(@upload_dir)
    extension = extension(entry.client_name, entry.client_type)
    filename = "#{entry.uuid}#{extension}"
    dest = Path.join(@upload_dir, filename)

    case Keyword.get(opts, :resize) do
      {max_width, max_height} ->
        resize_image!(meta.path, dest, max_width, max_height)

      nil ->
        File.cp!(meta.path, dest)
    end

    {:ok, "/uploads/#{filename}"}
  end

  @doc """
  Copies a plain `Plug.Upload` (e.g. an inline image posted from the CKEditor
  upload adapter) into `priv/static/uploads` and returns its public path.
  """
  def store_plug_upload(%Plug.Upload{} = upload) do
    File.mkdir_p!(@upload_dir)
    extension = extension(upload.filename, upload.content_type)
    filename = "#{Ecto.UUID.generate()}#{extension}"
    dest = Path.join(@upload_dir, filename)
    File.cp!(upload.path, dest)
    {:ok, "/uploads/#{filename}"}
  end

  defp extension(client_name, client_type) do
    case Path.extname(client_name || "") do
      "" -> ext_from_type(client_type)
      ext -> String.downcase(ext)
    end
  end

  defp ext_from_type("image/png"), do: ".png"
  defp ext_from_type("image/webp"), do: ".webp"
  defp ext_from_type("image/gif"), do: ".gif"
  defp ext_from_type("video/mp4"), do: ".mp4"
  defp ext_from_type("video/quicktime"), do: ".mov"
  defp ext_from_type("video/webm"), do: ".webm"
  defp ext_from_type("video/x-m4v"), do: ".m4v"
  defp ext_from_type(_), do: ".jpg"

  defp resize_image!(source, dest, max_width, max_height) do
    executable =
      System.find_executable("magick") || System.find_executable("convert") ||
        raise "ImageMagick is required to resize uploaded images"

    temp_dest = Path.join(Path.dirname(dest), ".#{Path.basename(dest)}.tmp#{Path.extname(dest)}")

    args = [
      source,
      "-auto-orient",
      "-strip",
      "-resize",
      "#{max_width}x#{max_height}>",
      "-quality",
      "85",
      temp_dest
    ]

    case System.cmd(executable, args, stderr_to_stdout: true) do
      {_output, 0} ->
        File.rename!(temp_dest, dest)

      {output, status} ->
        File.rm(temp_dest)
        raise "ImageMagick failed to resize upload (status #{status}): #{String.trim(output)}"
    end
  end
end
