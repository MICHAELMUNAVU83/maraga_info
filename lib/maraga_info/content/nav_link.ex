defmodule MaragaInfo.Content.NavLink do
  @moduledoc """
  A single entry in the public site navbar. Entries with no `parent_id` are
  top-level links or dropdowns; entries with a `parent_id` render as an item
  inside their parent's dropdown. Two levels deep only (top-level + children).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @placements ~w(left right)

  schema "nav_links" do
    field :label, :string
    field :href, :string
    field :placement, :string, default: "right"
    field :position, :integer, default: 0
    field :is_visible, :boolean, default: true

    belongs_to :parent, __MODULE__
    has_many :children, __MODULE__, foreign_key: :parent_id

    timestamps(type: :utc_datetime)
  end

  def placements, do: @placements

  @doc """
  The original hardcoded navbar, used to seed the `nav_links` table on
  migration and to restore it via the admin "Reset to defaults" action.
  Each entry is `{label, href, placement, children}`, where `children` is a
  list of `{label, href}` tuples.
  """
  def defaults do
    [
      {"About Us", nil, "left", [{"David Maraga", "/david-maraga"}, {"UGM Party", "/ugm-party"}]},
      {"Our Agenda", nil, "left",
       [{"Campaign Pillars", "/campaign-pillars"}, {"Manifesto", "#"}]},
      {"Resources", nil, "right",
       [
         {"Newsletters", "/newsletters"},
         {"News", "/news"},
         {"Blogs", "/blog"},
         {"Photos", "/media/photos"},
         {"Videos", "/media/videos"}
       ]},
      {"Press", nil, "right",
       [{"Press Releases", "/press-releases"}, {"Media Invitations", "/media-invitations"}]},
      {"Events", "/events", "right", []},
      {"Shop", "https://davidmaraga.shop", "right", []}
    ]
  end

  @doc false
  def changeset(nav_link, attrs) do
    nav_link
    |> cast(attrs, [:label, :href, :placement, :position, :is_visible, :parent_id])
    |> validate_required([:label])
    |> validate_length(:label, max: 60)
    |> validate_inclusion(:placement, @placements)
    |> foreign_key_constraint(:parent_id)
  end
end
