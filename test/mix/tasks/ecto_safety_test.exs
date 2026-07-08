defmodule Mix.Tasks.EctoSafetyTest do
  use ExUnit.Case, async: true

  test "ecto.drop is disabled" do
    Mix.Task.reenable("ecto.drop")

    assert_raise Mix.Error, ~r/disables destructive Ecto tasks/, fn ->
      Mix.Task.run("ecto.drop")
    end
  end

  test "ecto.reset is disabled" do
    Mix.Task.reenable("ecto.reset")

    assert_raise Mix.Error, ~r/disables destructive Ecto tasks/, fn ->
      Mix.Task.run("ecto.reset")
    end
  end
end
