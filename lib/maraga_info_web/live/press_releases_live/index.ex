defmodule MaragaInfoWeb.PressReleasesLive.Index do
  use MaragaInfoWeb, :live_view

  alias MaragaInfo.Content
  alias MaragaInfo.Content.Post
  alias MaragaInfoWeb.Seo

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :posts, [])}
  end

  @impl true
  def handle_params(_params, url, socket) do
    path = URI.parse(url).path
    config = scope_from_path(path)

    {:noreply,
     socket
     |> assign(:page_title, "#{config.title} | #{Seo.site_name()}")
     |> assign(:page_description, config.description)
     |> assign(:canonical_url, Seo.site_url() <> config.canonical_path)
     |> assign(:config, config)
     |> assign(:posts, Content.list_published_posts(scope: config.scope))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white">
      <.site_header base_path="/" />

      <section
        class="relative overflow-hidden bg-cover"
        style="background-position: center 35%; background-image: url('/images/maraga-town.jpg');"
      >
        <div class="absolute inset-0 bg-blueink/70"></div>
        <div class="relative z-10 mx-auto flex min-h-[42vh] w-full max-w-container flex-col items-center justify-center px-4 py-24 text-center lg:px-6">
          <h1 class="font-head text-3xl font-semibold uppercase tracking-[3px] text-white md:text-5xl lg:text-6xl">
            {@config.heading}
          </h1>
        </div>
      </section>

      <section class="bg-ghost py-16">
        <div class="mx-auto max-w-container px-4">
          <div class="mb-10 flex flex-wrap items-center justify-between gap-4">
            <h2 class="font-head text-2xl uppercase tracking-[0.08em] text-blueink">
              All <span class="text-crimson">{@config.title}</span>
            </h2>
          </div>

          <div
            :if={@posts == []}
            class="rounded-[8px] bg-white px-8 py-16 text-center shadow-[0_15px_40px_rgba(15,30,80,0.08)]"
          >
            <h3 class="font-head text-2xl uppercase tracking-[0.08em] text-blueink">
              No {@config.title |> String.downcase()} here yet
            </h3>
            <p class="mx-auto mt-3 max-w-xl text-base leading-7 text-grayink">
              Posts published under the "{@config.title}" category will appear here automatically.
            </p>
          </div>

          <div :if={@posts != [] && @config.layout == :list} class="divide-y divide-[#e6e6e6]">
            <.statement_row :for={post <- @posts} item={post} />
          </div>

          <div
            :if={@posts != [] && @config.layout == :cards}
            class="grid grid-cols-1 gap-7 md:grid-cols-2 lg:grid-cols-3"
          >
            <.news_card :for={post <- @posts} item={post} />
          </div>
        </div>
      </section>

      <.site_footer base_path={~p"/"} />
    </div>
    """
  end

  attr :item, :map, required: true

  # Press statements read as a descending list: the title sits inline and only
  # its last word is hyperlinked through to the full article.
  defp statement_row(assigns) do
    {lead, last_word} = split_last_word(assigns.item.title)

    assigns = assign(assigns, lead: lead, last_word: last_word)

    ~H"""
    <div class="flex flex-col gap-1 py-4 md:flex-row md:items-baseline md:justify-between md:gap-6">
      <h4 class="font-head text-lg uppercase tracking-[.5px] text-blueink">
        <span :if={@lead != ""}>{@lead}</span>
        <.link
          navigate={~p"/blog/#{@item.slug}"}
          class="text-crimson underline decoration-crimson/40 underline-offset-4 transition hover:decoration-crimson"
        >
          {@last_word}
        </.link>
      </h4>
      <span class="shrink-0 text-xs font-bold uppercase tracking-[2px] text-grayink">
        {format_post_date(@item.published_at)}
      </span>
    </div>
    """
  end

  # "Statement on Ebola" -> {"Statement on", "Ebola"}
  defp split_last_word(title) do
    case String.split(String.trim(title || ""), ~r/\s+/, trim: true) do
      [] -> {"", "Read statement"}
      [single] -> {"", single}
      words -> {Enum.drop(words, -1) |> Enum.join(" "), List.last(words)}
    end
  end

  attr :item, :map, required: true

  defp news_card(assigns) do
    ~H"""
    <article class="group flex flex-col overflow-hidden rounded-[5px] bg-white shadow-[0_15px_40px_rgba(15,30,80,0.08)]">
      <.post_card_preview item={@item} />

      <div class="flex flex-1 flex-col p-7">
        <div class="flex items-center gap-2 text-xs">
          <span class="font-bold uppercase tracking-[2px] text-crimson">
            {format_post_date(@item.published_at)}
          </span>
          <span class="text-grayink">|</span>
          <span class="font-bold uppercase tracking-[1px] text-grayink">
            {@item.category}
          </span>
        </div>
        <.link navigate={~p"/blog/#{@item.slug}"}>
          <h4 class="mt-3 font-head text-2xl uppercase tracking-[.5px] text-blueink transition hover:text-crimson">
            {@item.title}
          </h4>
        </.link>
        <div class="my-5 h-px w-full bg-[#e6e6e6]"></div>
        <p class="mt-0 text-base leading-7 text-grayink">
          {Post.summary(@item)}
        </p>
      </div>
    </article>
    """
  end

  defp format_post_date(nil), do: "Draft"

  defp format_post_date(%DateTime{} = published_at),
    do: Calendar.strftime(published_at, "%b %-d, %Y")

  defp scope_from_path(path) do
    if String.ends_with?(path, "/media-invitations") do
      %{
        scope: :media_invitations,
        title: "Media Invitations",
        heading: "Maraga in the Media",
        canonical_path: "/media-invitations",
        layout: :cards,
        description:
          "Official media advisories and invitation notices from David Maraga's 2027 campaign."
      }
    else
      %{
        scope: :press_releases,
        title: "Press Releases",
        heading: "Press Releases",
        canonical_path: "/press-releases",
        layout: :list,
        description: "Official press releases and statements from David Maraga's 2027 campaign."
      }
    end
  end
end
