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

  test "normalizes and truncates extracted PDF text" do
    assert Uploads.normalize_pdf_text("  A PDF\n\npreview with   spacing.  ", 100) ==
             "A PDF preview with spacing."

    assert Uploads.normalize_pdf_text("First useful words followed by more content", 24) ==
             "First useful words…"

    assert Uploads.normalize_pdf_text(" \n\t ", 100) == nil
  end

  test "only extracts previously stored PDFs from local upload URLs" do
    assert Uploads.extract_stored_pdf_preview("https://example.com/document.pdf") == nil
    assert Uploads.extract_stored_pdf_preview("/uploads/nested/document.pdf") == nil
    assert Uploads.extract_stored_pdf_preview("/images/document.pdf") == nil
  end
end
