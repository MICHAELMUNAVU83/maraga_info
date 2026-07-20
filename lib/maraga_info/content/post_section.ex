defmodule MaragaInfo.Content.PostSection do
  @moduledoc """
  A single content block within a blog post. A post can have many sections,
  each with an optional heading, body copy, and any number of attachments.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :heading, :string
    field :body, :string
    field :image_urls, {:array, :string}, default: []
    field :position, :integer, default: 0
  end

  @doc false
  def changeset(section, attrs) do
    section
    |> cast(attrs, [:heading, :body, :image_urls, :position])
    |> update_change(:image_urls, &reject_blank/1)
    |> validate_section_not_empty()
  end

  defp reject_blank(nil), do: []

  defp reject_blank(urls) when is_list(urls) do
    Enum.reject(urls, &(is_nil(&1) or String.trim(to_string(&1)) == ""))
  end

  defp validate_section_not_empty(changeset) do
    heading = get_field(changeset, :heading)
    body = get_field(changeset, :body)
    attachments = get_field(changeset, :image_urls) || []

    if blank?(heading) and blank?(body) and attachments == [] do
      add_error(changeset, :body, "section needs a heading, text, or at least one attachment")
    else
      changeset
    end
  end

  defp blank?(nil), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_), do: false
end
