defmodule MaragaInfoWeb.Uploads do
  @moduledoc """
  Helpers for storing LiveView uploads on local disk and returning the public
  URL that can be served by `Plug.Static` from `priv/static/uploads`.
  """

  @upload_dir Path.join(["priv", "static", "uploads"])
  @pdf_extraction_timeout 2_000

  @doc """
  Copies an uploaded entry into `priv/static/uploads` and returns its public
  path (e.g. `/uploads/ab12cd34.jpg`).
  """
  def store_entry(meta, entry) do
    File.mkdir_p!(@upload_dir)
    extension = extension(entry.client_name, entry.client_type)
    filename = "#{entry.uuid}#{extension}"
    dest = Path.join(@upload_dir, filename)
    File.cp!(meta.path, dest)
    {:ok, "/uploads/#{filename}"}
  end

  @doc """
  Stores an upload and, for text-based PDFs, returns a short extracted preview.

  PDF extraction is optional: when `pdftotext` is unavailable or the PDF has no
  embedded text, `preview_text` is `nil` and the upload still succeeds.
  """
  def store_entry_with_preview(meta, entry) do
    with {:ok, url} <- store_entry(meta, entry) do
      preview_text =
        if pdf?(url) do
          url
          |> local_upload_path()
          |> extract_pdf_preview()
        end

      {:ok, %{url: url, preview_text: preview_text}}
    end
  end

  @doc "Extracts a short preview from the first three pages of a text-based PDF."
  def extract_pdf_preview(path, max_length \\ 240) when is_binary(path) do
    with executable when is_binary(executable) <- System.find_executable("pdftotext"),
         true <- valid_pdf?(path),
         {text, 0} <- run_pdf_extraction(executable, path) do
      normalize_pdf_text(text, max_length)
    else
      _ -> nil
    end
  rescue
    _ -> nil
  end

  @doc "Extracts preview text from a previously stored local PDF URL."
  def extract_stored_pdf_preview(url, max_length \\ 240) do
    if pdf?(url) and local_upload_url?(url) do
      url
      |> local_upload_path()
      |> extract_pdf_preview(max_length)
    end
  end

  @doc false
  def normalize_pdf_text(text, max_length) when is_binary(text) and max_length > 0 do
    text
    |> String.replace(~r/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/u, " ")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
    |> truncate_preview(max_length)
    |> case do
      "" -> nil
      preview -> preview
    end
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

  def pdf?(url) when is_binary(url) do
    case URI.parse(url).path do
      path when is_binary(path) -> String.downcase(Path.extname(path)) == ".pdf"
      _ -> false
    end
  end

  def pdf?(_url), do: false

  defp local_upload_path(url), do: Path.join(@upload_dir, Path.basename(url))

  defp local_upload_url?(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{host: nil, path: "/uploads/" <> filename} ->
        filename != "" and Path.basename(filename) == filename

      _ ->
        false
    end
  end

  defp local_upload_url?(_url), do: false

  defp valid_pdf?(path) do
    case File.read(path) do
      {:ok, <<"%PDF-", _::binary>> = contents} -> String.contains?(contents, "%%EOF")
      _ -> false
    end
  end

  defp run_pdf_extraction(executable, path) do
    task =
      Task.async(fn ->
        System.cmd(
          executable,
          ["-f", "1", "-l", "3", "-enc", "UTF-8", path, "-"],
          stderr_to_stdout: true
        )
      end)

    case Task.yield(task, @pdf_extraction_timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      _ -> :error
    end
  end

  defp truncate_preview(text, max_length) do
    if String.length(text) <= max_length do
      text
    else
      text
      |> String.slice(0, max_length)
      |> String.replace(~r/\s+\S*$/u, "")
      |> Kernel.<>("…")
    end
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
  defp ext_from_type("application/pdf"), do: ".pdf"
  defp ext_from_type("video/mp4"), do: ".mp4"
  defp ext_from_type("video/quicktime"), do: ".mov"
  defp ext_from_type("video/webm"), do: ".webm"
  defp ext_from_type("video/x-m4v"), do: ".m4v"
  defp ext_from_type(_), do: ".jpg"
end
