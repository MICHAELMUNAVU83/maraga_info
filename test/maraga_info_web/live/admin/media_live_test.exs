defmodule MaragaInfoWeb.Admin.MediaLiveTest do
  use MaragaInfoWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "uploaded gallery video clears the required error", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin/media/videos")
    render_click(view, "new")

    html =
      view
      |> file_input("#media-form", :video, [
        %{name: "gallery-clip.mp4", content: "test video content", type: "video/mp4"}
      ])
      |> render_upload("gallery-clip.mp4")

    assert html =~ ~r{<video src="/uploads/.+\.mp4"}
    refute html =~ "A video file is required."

    [_, upload_url] = Regex.run(~r{<video src="(/uploads/.+\.mp4)"}, html)
    on_exit(fn -> File.rm(Path.join("priv/static", upload_url)) end)
  end
end
