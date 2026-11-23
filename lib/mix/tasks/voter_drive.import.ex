defmodule Mix.Tasks.VoterDrive.Import do
  use Mix.Task

  @shortdoc "Seeds voter-drive registrations from an XLSX export"

  @impl true
  def run([path]) do
    Mix.Task.run("app.start")

    case MaragaInfo.VoterDrive.import_file(Path.expand(path)) do
      {:ok, summary} ->
        Mix.shell().info(
          "Processed #{summary.total}: #{summary.inserted} inserted, " <>
            "#{summary.updated} updated, #{summary.failed} failed."
        )

      {:error, reason} ->
        Mix.raise("Voter-drive import failed: #{inspect(reason)}")
    end
  end

  def run(_args), do: Mix.raise("Usage: mix voter_drive.import PATH_TO_XLSX")
end
