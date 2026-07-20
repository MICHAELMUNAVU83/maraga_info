defmodule MaragaInfoWeb.UploadsTest do
  use ExUnit.Case, async: true

  alias MaragaInfoWeb.Uploads

  test "stores an upload without modifying its contents" do
    source = Path.join(System.tmp_dir!(), "upload-source-#{Ecto.UUID.generate()}.png")
    uuid = Ecto.UUID.generate()
    destination = Path.join(["priv", "static", "uploads", "#{uuid}.png"])
    contents = "original upload contents"

    on_exit(fn ->
      File.rm(source)
      File.rm(destination)
    end)

    File.write!(source, contents)

    entry = %{client_name: "cover.png", client_type: "image/png", uuid: uuid}
    expected_url = "/uploads/#{uuid}.png"

    assert {:ok, ^expected_url} = Uploads.store_entry(%{path: source}, entry)

    assert File.read!(destination) == contents
  end

  test "recognizes PDF attachment URLs" do
    assert Uploads.pdf?("/uploads/campaign-brief.PDF")
    assert Uploads.pdf?("https://example.com/brief.pdf?download=1")
    refute Uploads.pdf?("/uploads/campaign-photo.png")
    refute Uploads.pdf?(nil)
  end
end
