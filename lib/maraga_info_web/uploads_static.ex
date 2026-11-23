defmodule MaragaInfoWeb.UploadsStatic do
  @moduledoc false
  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    # Build these small options at request time so UPLOADS_DIR remains runtime
    # configurable in releases. Plug.Static also handles range requests needed
    # by uploaded videos and PDFs.
    options =
      Plug.Static.init(
        at: "/uploads",
        from: MaragaInfoWeb.Uploads.directory(),
        gzip: false
      )

    Plug.Static.call(conn, options)
  end
end
