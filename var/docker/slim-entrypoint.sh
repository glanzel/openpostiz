#!/bin/sh
# -----------------------------------------------------------------------------
#  Entrypoint for the slim runtime image.
#
#  Replaces the old chain:
#    sh -> pnpm run pm2 -> pnpm run pm2-run -> pnpm run --parallel pm2
#       -> 3x "pm2 start pnpm -- start" -> dotenv -> node/next
#  with:
#    prisma db push -> wait for Temporal -> nginx -> pm2-runtime (3 processes)
#
#  pnpm is not installed in the runtime image; the prisma CLI from
#  /opt/runtime-tools and pm2-runtime are used directly.
# -----------------------------------------------------------------------------
set -e

# Keep the old "dotenv -e ../../.env" behaviour without overwriting variables
# that were passed to the container.
DOTENV=""
if [ -f /app/.env ] && [ -x /app/node_modules/.bin/dotenv ]; then
  DOTENV="/app/node_modules/.bin/dotenv -e /app/.env --"
fi

cd /app

# Make sure the database schema is up to date. Retry while the database is
# still starting, then fail so the container restart policy can take over.
tries=0
until $DOTENV /opt/runtime-tools/node_modules/.bin/prisma db push \
  --skip-generate \
  --schema ./libraries/nestjs-libraries/src/database/prisma/schema.prisma; do
  tries=$((tries + 1))
  if [ "$tries" -ge 30 ]; then
    echo "Database schema push failed after $tries attempts, giving up."
    exit 1
  fi
  echo "Database not ready yet, retrying in 2s ($tries/30)..."
  sleep 2
done

# The Temporal worker connects exactly once at start-up. If Temporal is still
# starting, the orchestrator would keep running without polling any task
# queue. Wait for the port before starting the apps (max. ~180s, then start
# anyway so a misconfigured host does not block forever).
if [ -n "${TEMPORAL_ADDRESS:-}" ]; then
  host=${TEMPORAL_ADDRESS%%:*}
  port=${TEMPORAL_ADDRESS##*:}
  [ "$host" = "$port" ] && port=7233

  echo "Waiting for Temporal at $host:$port ..."
  tries=0
  until TEMPORAL_HOST="$host" TEMPORAL_PORT="$port" node -e '
    const net = require("net");
    const s = net.connect({ host: process.env.TEMPORAL_HOST, port: Number(process.env.TEMPORAL_PORT) });
    s.setTimeout(2000);
    s.on("connect", () => process.exit(0));
    s.on("error", () => process.exit(1));
    s.on("timeout", () => { s.destroy(); process.exit(1); });
  '; do
    tries=$((tries + 1))
    if [ "$tries" -ge 90 ]; then
      echo "WARNING: Temporal not reachable after 180s – starting anyway (worker may stay inactive)."
      break
    fi
    sleep 2
  done
  if [ "$tries" -lt 90 ]; then
    echo "Temporal is reachable."
  fi
fi

# nginx listens on :5000 and proxies /api -> :3000 and / -> :4200.
nginx

# pm2-runtime keeps the three node processes in the foreground.
exec $DOTENV pm2-runtime /app/ecosystem.config.cjs
