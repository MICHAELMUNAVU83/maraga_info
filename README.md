# David Maraga Info

A Phoenix LiveView website covering David Kenani Maraga — Kenya's former Chief Justice and 2027 presidential aspirant. It serves a public marketing/landing site and news blog, backed by an authenticated admin area for managing posts and media.

## Features

- **Public site** — a landing page (hero, mission, agenda, gallery, newsletter) and a news/blog section.
- **Blog** — SEO-optimised article pages with structured data (`schema.org` `NewsArticle`), Open Graph metadata, sectioned content (heading + body + images), previous/next navigation, and social sharing (Facebook, X, WhatsApp, LinkedIn, Telegram, email, copy link).
- **Admin dashboard** — authenticated CRUD for posts, newsletters, press releases, media invitations, photos, and videos at `/admin`, including multi-section content, newsletter embeds, richer text formatting, and local media uploads.
- **Accounts** — email/password authentication with registration, confirmation, password reset, and an `is_admin` role (the first registered user is auto-promoted to admin).

## Tech stack

- [Elixir](https://elixir-lang.org/) + [Phoenix](https://www.phoenixframework.org/) 1.7
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view) 1.0
- [Ecto](https://hexdocs.pm/ecto) + PostgreSQL
- [Tailwind CSS](https://tailwindcss.com/) + [esbuild](https://esbuild.github.io/) for assets
- [Bandit](https://hexdocs.pm/bandit) web server
- [bcrypt_elixir](https://hexdocs.pm/bcrypt_elixir) for password hashing
- [Swoosh](https://hexdocs.pm/swoosh) + [Finch](https://hexdocs.pm/finch) for email

## Prerequisites

- Elixir `~> 1.14` and a compatible Erlang/OTP
- PostgreSQL (running and reachable; default config expects `postgres`/`postgres` on `localhost`)
- Node is **not** required — assets are built with the `esbuild` and `tailwind` Mix tasks

## Getting started

```bash
# Create your local env file (runtime.exs auto-loads it)
cp .env.example .env

# Install deps, create & migrate the database, build assets, and seed data
mix setup

# Start the server
mix phx.server
# or inside IEx:
iex -S mix phx.server
```

Then visit [`localhost:4000`](http://localhost:4000).

`mix setup` runs `deps.get`, `ecto.setup` (create + migrate + seed), `assets.setup`, and `assets.build`.
`config/runtime.exs` auto-loads `.env` for local runs, so `BREVO_API_KEY` and related mail vars are available when you start Phoenix.

## Database & seeds

```bash
mix ecto.create               # create the database
mix ecto.migrate              # run migrations
mix run priv/repo/seeds.exs   # seed an admin user + sample blog posts
mix ecto.reset                # drop, recreate, migrate, and re-seed
```

The seed script ([`priv/repo/seeds.exs`](priv/repo/seeds.exs)) creates:

- An **admin user** — `admin@davidmaraga.info` / `123456` (promoted to admin). Change this before any real deployment.
- **Four published blog posts** with sectioned content and images from `priv/static/images/`.

> Post seeding is idempotent by `slug`: existing posts are skipped. To refresh post content after editing the seeds, delete the rows (or run `mix ecto.reset`) before re-seeding.

## Admin area

1. Sign in at [`/users/log_in`](http://localhost:4000/users/log_in) with the seeded admin credentials.
2. Manage content at [`/admin`](http://localhost:4000/admin):

- `/admin/posts` — general news and article posts
- `/admin/newsletters` — newsletter issues with volume numbers and Canva embeds
- `/admin/press-releases`, `/admin/media-invitations` — press-facing content
- `/admin/media/photos`, `/admin/media/videos` — public gallery assets
- `/admin/pages/*`, `/admin/settings` — additional admin sections

Uploaded images and videos are stored under `priv/static/uploads/` and served from `/uploads`.

## Routes overview

| Path                                     | Description                      |
| ---------------------------------------- | -------------------------------- |
| `/`                                      | Public landing page              |
| `/blog/:slug`                            | Public article page              |
| `/users/log_in`, `/users/reset_password` | Authentication                   |
| `/users/settings`                        | Account settings (authenticated) |
| `/admin`, `/admin/blogs/*`               | Admin dashboard (admin only)     |
| `/dev/dashboard`                         | LiveDashboard (dev only)         |

## Tests

```bash
mix test
```

Tests automatically create and migrate the test database first.

## Project structure

```
lib/
  maraga_info/            # Core domain
    accounts/             # Users, authentication
    content/              # Posts and post sections
  maraga_info_web/        # Web layer
    live/                 # LiveViews (home, blog, admin, auth)
    components/           # Shared HEEx components
    controllers/          # Session controller
priv/
  repo/                   # Migrations and seeds
  static/                 # Images, uploads, static assets
assets/                   # CSS, JS, Tailwind config
```

## Deployment

This is a standard Phoenix release. Build minified assets with `mix assets.deploy` and follow the official [Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html). Be sure to set `SECRET_KEY_BASE`, `DATABASE_URL`, and `PHX_HOST`, and replace the seeded admin credentials.
