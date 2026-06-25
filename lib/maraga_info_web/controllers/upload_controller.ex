defmodule MaragaInfoWeb.UploadController do
  @moduledoc """
  Receives inline image uploads from the CKEditor SimpleUploadAdapter and stores
  them through `MaragaInfoWeb.Uploads`. Responses follow the shape the adapter
  expects: `{"url": "..."}` on success, `{"error": {"message": "..."}}` on error.
  """
  use MaragaInfoWeb, :controller

  alias MaragaInfoWeb.Uploads

  @max_bytes 8 * 1024 * 1024
  @accepted ~w(image/jpeg image/png image/webp image/gif)

  def image(conn, %{"upload" => %Plug.Upload{} = upload}) do
    cond do
      upload.content_type not in @accepted ->
        error(conn, "Unsupported file type. Use JPG, PNG, WEBP or GIF.")

      File.stat!(upload.path).size > @max_bytes ->
        error(conn, "Image is too large (max 8MB).")

      true ->
        {:ok, url} = Uploads.store_plug_upload(upload)
        json(conn, %{url: url})
    end
  end

  def image(conn, _params), do: error(conn, "No file was uploaded.")

  defp error(conn, message) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: %{message: message}})
  end
end
