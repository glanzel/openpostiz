# Fork notes

Fork of [gitroomhq/postiz-app](https://github.com/gitroomhq/postiz-app) for
self-hosting with a slim Docker setup. This file is the contract for automated
rebases and LLM agents.

## Intentional changes (do not "clean up")

| File | Purpose |
|---|---|
| `Dockerfile.slim` | Multi-stage build: all deps/build in a builder stage; runtime without g++/make/python and (intended) without dev deps. |
| `var/docker/slim-entrypoint.sh` | Runs nginx, `prisma db push`, waits for Temporal, then `pm2-runtime`. |
| `var/docker/ecosystem.config.cjs` | Starts backend/frontend/orchestrator directly (no pnpm wrappers). |
| `apps/orchestrator/src/main.ts` | Opt-in worker watchdog (`TEMPORAL_WORKER_WATCHDOG=1`): exits if no Temporal worker is running so the supervisor restarts it. |
| `postiz-slim.yaml` | Sanitized self-hosting compose: slim image, no Elasticsearch, `temporal-visibility-init`. |
| `.github/workflows/build-slim.yml` | Builds `ghcr.io/<owner>/<repo>:slim` for amd64 + arm64. |
| `.github/workflows/auto-rebase.yml` | Daily rebase onto `upstream/main`, with backup branch and OpenCode conflict resolution. |
| `.github/auto-rebase-prompt.md` | Instructions the OpenCode agent follows to resolve rebase conflicts. |
| `README.md` | Short fork notice at the top (shown on the GitHub landing page). |

## Invariants

- `package.json` and `pnpm-lock.yaml` must stay **identical to upstream**.
- No Elasticsearch. Temporal uses PostgreSQL visibility, plus `temporal-visibility-init`
  (removes the two default Text search attributes so Postiz's two fit the limit of 3).
- The worker watchdog is **off** unless `TEMPORAL_WORKER_WATCHDOG=1`.
- Image tag: `ghcr.io/glanzel/openpostiz:slim`.

## Branching

- `main` is the single maintenance branch. **All fork changes live in one
  squashed commit** on top of `upstream/main`, so a rebase only ever replays a
  single commit.
- `auto-rebase.yml` rebases `main` onto `upstream/main` daily.
- Before every rebase attempt the workflow pushes `backup/main` (rolling) and
  `backup/main-<timestamp>`.
- On conflict, an **OpenCode agent** resolves it using
  `.github/auto-rebase-prompt.md`. If the agent fails, the rebase is aborted,
  `main` is left untouched and an issue is created.
- The old `feat/slim-image` branch is retired; all changes live on `main`.

## Conflict rules

- `package.json`, `pnpm-lock.yaml`: always take upstream.
- `Dockerfile.slim`, `var/docker/**`, `postiz-slim.yaml`: keep ours.
- `apps/orchestrator/src/main.ts`: keep our watchdog on top of upstream's version.
- `README.md`: take upstream and re-add the fork notice at the top.
- Everything else: prefer upstream, unless it breaks the rules above.

## Reconstructing context

```bash
git log --oneline upstream/main..HEAD
git diff upstream/main...HEAD
```

Commit messages are descriptive; use them together with this file.
