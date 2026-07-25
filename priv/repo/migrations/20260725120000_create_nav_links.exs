defmodule MaragaInfo.Repo.Migrations.CreateNavLinks do
  use Ecto.Migration

  def change do
    create table(:nav_links) do
      add :label, :string, null: false
      add :href, :string
      add :placement, :string, null: false, default: "right"
      add :position, :integer, null: false, default: 0
      add :is_visible, :boolean, null: false, default: true
      add :parent_id, references(:nav_links, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:nav_links, [:parent_id])
    create index(:nav_links, [:placement, :position])

    flush()

    seed_default_nav_links()
  end

  # Seeds the current hardcoded navbar so the admin editor starts pre-populated
  # instead of leaving the public navbar empty after this migration runs.
  defp seed_default_nav_links do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Enum.with_index(MaragaInfo.Content.NavLink.defaults(), fn {label, href, placement, children},
                                                               position ->
      parent_id = insert_nav_link(label, href, placement, position, now)

      Enum.with_index(children, fn {child_label, child_href}, child_position ->
        insert_nav_link(child_label, child_href, placement, child_position, now, parent_id)
      end)
    end)
  end

  defp insert_nav_link(label, href, placement, position, now, parent_id \\ nil) do
    {:ok, result} =
      repo().query(
        "INSERT INTO nav_links (label, href, placement, position, is_visible, parent_id, inserted_at, updated_at) VALUES ($1, $2, $3, $4, true, $5, $6, $6) RETURNING id",
        [label, href, placement, position, parent_id, now]
      )

    [[id]] = result.rows
    id
  end
end
