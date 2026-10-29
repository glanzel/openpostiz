#!/bin/sh
# -----------------------------------------------------------------------------
#  Slim entrypoint: ersetzt die pnpm/pm2-Wrapper-Kette.
#
#  Vorher:  sh -> pnpm run pm2 -> pnpm run pm2-run -> pnpm run --parallel pm2
#                 -> 3x "pm2 start pnpm -- start" -> dotenv -> node/next
#  Jetzt:   nginx -> prisma db push -> auf Temporal warten -> pm2-runtime
#
#  Warum auf Temporal warten?
#  Der Temporal-Worker (nestjs-temporal-core) versucht die Verbindung beim
#  Start GENAU EINMAL. Ist Temporal dann noch nicht erreichbar, wird null
#  zurückgegeben und der Worker pollt dauerhaft nicht mehr – ohne Crash,
#  ohne PM2-Restart. Deshalb warten wir vor dem App-Start auf den Port.
# -----------------------------------------------------------------------------
set -e

# Optionales .env laden (Ersatz fuer "dotenv -e ../../.env --").
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

# 3) Auf Temporal warten (nur wenn konfiguriert). Max. ~180s, danach Start
#    mit Warnung, damit ein falsch konfigurierter Host nicht ewig blockiert.
if [ -n "${TEMPORAL_ADDRESS:-}" ]; then
  host=${TEMPORAL_ADDRESS%%:*}
  port=${TEMPORAL_ADDRESS##*:}
  [ "$host" = "$port" ] && port=7233

  echo "Warte auf Temporal unter $host:$port ..."
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
      echo "WARNUNG: Temporal nach 180s nicht erreichbar – starte trotzdem (Worker bleibt evtl. inaktiv)."
      break
    fi
    sleep 2
  done
  if [ "$tries" -lt 90 ]; then
    echo "Temporal erreichbar."
  fi
fi

# 4) Apps im Vordergrund starten (pm2-runtime uebernimmt Restart + Logs)
exec pm2-runtime /app/ecosystem.config.cjs
