#!/bin/sh
# -----------------------------------------------------------------------------
#  Slim entrypoint: ersetzt die pnpm/pm2-Wrapper-Kette.
#
#  Vorher:  sh -> pnpm run pm2 -> pnpm run pm2-run -> pnpm run --parallel pm2
#                 -> 3x "pm2 start pnpm -- start" -> dotenv -> node/next
#  Jetzt:   dieses Skript -> prisma db push -> pm2-runtime (direkte node/next)
#
#  Ersparnis: keine mehrfachen pnpm-Wrapper + kein dotenv-Wrapper pro App.
# -----------------------------------------------------------------------------
set -e

# Optionales .env laden (Ersatz fuer "dotenv -e ../../.env --").
# In Containern kommt die Konfiguration normalerweise aus den Env-Variablen.
if [ -f /app/.env ]; then
  set -a
  . /app/.env
  set +a
fi

# 1) nginx (lauscht auf 5000, proxied /api -> 3000, / -> 4200)
nginx

# 2) Datenbank-Schema aktualisieren (lokales prisma, kein Netzwerk-Download)
cd /app
/app/node_modules/.bin/prisma db push \
  --schema ./libraries/nestjs-libraries/src/database/prisma/schema.prisma

# 3) Apps im Vordergrund starten (pm2-runtime uebernimmt Restart + Logs)
exec pm2-runtime /app/ecosystem.config.cjs
