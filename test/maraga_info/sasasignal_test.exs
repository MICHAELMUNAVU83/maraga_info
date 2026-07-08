defmodule MaragaInfo.SasasignalTest do
  use ExUnit.Case, async: true

  alias MaragaInfo.Sasasignal

  describe "build_recipients_csv/1" do
    test "builds the expected csv with blank per-recipient messages by default" do
      assert {:ok, csv} =
               Sasasignal.build_recipients_csv([
                 "0700123456",
                 %{phone: "0711223344"}
               ])

      assert csv == "\"phone\",\"message\"\n\"0700123456\",\"\"\n\"0711223344\",\"\"\n"
    end

    test "keeps an explicit per-recipient message when provided" do
      assert {:ok, csv} =
               Sasasignal.build_recipients_csv([
                 %{phone: "0700123456", message: "Custom line"}
               ])

      assert csv == "\"phone\",\"message\"\n\"0700123456\",\"Custom line\"\n"
    end
  end

  describe "build_recipients_csv/1 validation" do
    test "returns an error when recipients are missing" do
      assert {:error, {:invalid_payload, "recipients must contain at least one phone number"}} =
               Sasasignal.build_recipients_csv([])
    end
  end
end
