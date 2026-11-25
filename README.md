# OpenPostiz

**A lean self-hosted fork of [Postiz](https://github.com/gitroomhq/postiz-app), the excellent open-source social media scheduling platform.**

[![Upstream](https://img.shields.io/badge/upstream-gitroomhq%2Fpostiz--app-6f42c1)](https://github.com/gitroomhq/postiz-app)
[![License](https://img.shields.io/badge/license-AGPL--3.0-blue)](./LICENSE)

OpenPostiz packages Postiz for small self-hosted servers: one multi-stage image, no
Elasticsearch, no build tools or dev dependencies at runtime. All product credit belongs
to the [Postiz team](https://github.com/gitroomhq/postiz-app) — this fork only changes
packaging and deployment. For the managed service, see [Postiz Cloud](https://postiz.com).

## Install

```bash
git clone https://github.com/glanzel/openpostiz.git
cd openpostiz
# edit postiz-slim.yaml: MAIN_URL, FRONTEND_URL, NEXT_PUBLIC_BACKEND_URL, JWT_SECRET
docker compose -f postiz-slim.yaml up -d
```

Open `http://your-server:4007` (or point your reverse proxy at port `4007`).

Generate a JWT secret with `openssl rand -base64 48`. Change the PostgreSQL password and
the matching `DATABASE_URL` before exposing the stack to the internet.

## What is Postiz?

[Postiz](https://postiz.com) schedules and analyses content for 28+ channels, including X,
LinkedIn, Instagram, YouTube, TikTok, Facebook, Threads, Pinterest, Reddit, Mastodon,
Bluesky, Discord and Slack. It includes a calendar, analytics, teams, a media library,
AI features, a public API and webhooks.

- [Source code](https://github.com/gitroomhq/postiz-app) · [Docs](https://docs.postiz.com) · [Discord](https://discord.postiz.com)

## Why this fork?

- Multi-stage image: no compilers, Python, pnpm or dev dependencies at runtime.
- Temporal without Elasticsearch.
- Direct `pm2-runtime` instead of nested pnpm wrappers.
- `package.json` and `pnpm-lock.yaml` stay identical to upstream.

## Configuration

Everything lives in `postiz-slim.yaml`. The required settings are:

| Variable | Value |
|---|---|
| `MAIN_URL` | Public URL, e.g. `https://social.example.com` |
| `FRONTEND_URL` | Same public URL |
| `NEXT_PUBLIC_BACKEND_URL` | `<MAIN_URL>/api` |
| `JWT_SECRET` | Long random string |
| `DATABASE_URL` | PostgreSQL connection string |
| `REDIS_URL` | Redis connection string |

Social platform credentials, AI keys and Cloudflare R2 are optional. See
[`postiz-slim.yaml`](./postiz-slim.yaml), [`.env.example`](./.env.example) and the
[Postiz configuration reference](https://docs.postiz.com/configuration/reference).

## Build from source

```bash
docker build -f Dockerfile.slim -t postiz:slim .
```

Or build and start the lean stack in one go:

```bash
docker compose -f postiz-slim.yaml -f docker-compose.slim.yaml up -d --build
```

## Development

```bash
cp .env.example .env
pnpm install
pnpm dev:docker
pnpm dev
```

Node.js 22 and pnpm 10 are required.

## Updates, backups and troubleshooting

```bash
docker compose -f postiz-slim.yaml pull && docker compose -f postiz-slim.yaml up -d
```

Back up the database (`postgres-volume`) and the uploads volume (`postiz-uploads`). The
container applies Prisma schema changes on start. Logs:
`docker compose -f postiz-slim.yaml logs -f postiz`.

If the app returns `502` right after start, wait for the database and Temporal; both are
checked at startup. Set `DISABLE_REGISTRATION=true` after creating your account.

## Credits and license

Huge thanks to the **Postiz team and community** for building and maintaining the product
this fork is based on: [GitHub](https://github.com/gitroomhq/postiz-app) ·
[Website](https://postiz.com) · [Docs](https://docs.postiz.com) ·
[Postiz Cloud](https://platform.postiz.com) · [Discord](https://discord.postiz.com).

OpenPostiz is released under the **AGPL-3.0**, the same license as Postiz. See
[LICENSE](./LICENSE). OpenPostiz is an independent fork and is not affiliated with Gitroom.
