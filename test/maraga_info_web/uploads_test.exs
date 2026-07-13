defmodule MaragaInfoWeb.UploadsTest do
  use ExUnit.Case, async: true

  alias MaragaInfoWeb.Uploads

  test "resizes an image to fit within the requested bounds without changing its aspect ratio" do
    source = Path.join(System.tmp_dir!(), "upload-source-#{Ecto.UUID.generate()}.png")
    uuid = Ecto.UUID.generate()
    destination = Path.join(["priv", "static", "uploads", "#{uuid}.png"])

    on_exit(fn ->
      File.rm(source)
      File.rm(destination)
    end)

    image_magick = System.find_executable("magick") || System.find_executable("convert")
    identify = System.find_executable("identify")

    assert image_magick
    assert identify
    assert {_, 0} = System.cmd(image_magick, ["-size", "2400x1800", "xc:red", source])

    entry = %{client_name: "cover.png", client_type: "image/png", uuid: uuid}
    expected_url = "/uploads/#{uuid}.png"

    assert {:ok, ^expected_url} =
             Uploads.store_entry(%{path: source}, entry, resize: {1600, 1200})

    assert {"1600x1200", 0} =
             System.cmd(identify, ["-format", "%wx%h", destination])
  end
end
