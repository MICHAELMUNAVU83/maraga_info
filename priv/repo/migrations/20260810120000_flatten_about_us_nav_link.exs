defmodule MaragaInfo.Repo.Migrations.FlattenAboutUsNavLink do
  use Ecto.Migration

  # Replaces the "About Us" dropdown with two standalone top-level links, so
  # existing databases match the new defaults in MaragaInfo.Content.NavLink.
  def up do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    case repo().query!("SELECT id, position FROM nav_links WHERE label = 'About Us' AND parent_id IS NULL") do
      %{rows: [[about_id, position] | _]} ->
        # Make room for the second standalone link.
        repo().query!(
          "UPDATE nav_links SET position = position + 1, updated_at = $2 WHERE parent_id IS NULL AND placement = 'left' AND position > $1",
          [position, now]
        )

        repo().query!(
          "UPDATE nav_links SET label = 'David Maraga Profile', href = '/david-maraga', parent_id = NULL, placement = 'left', position = $1, updated_at = $2 WHERE id = $3",
          [position, now, about_id]
        )

        repo().query!(
          "INSERT INTO nav_links (label, href, placement, position, is_visible, parent_id, inserted_at, updated_at) VALUES ('UGM Party', '/ugm-party', 'left', $1, true, NULL, $2, $2)",
          [position + 1, now]
        )

        # Drop the old dropdown children.
        repo().query!("DELETE FROM nav_links WHERE parent_id = $1", [about_id])

      _ ->
        :ok
    end
  end

  def down, do: :ok
end
