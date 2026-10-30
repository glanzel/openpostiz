import { initializeSentry } from '@gitroom/nestjs-libraries/sentry/initialize.sentry';
initializeSentry('orchestrator', true);
import 'source-map-support/register';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
dayjs.extend(utc);

import { INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { TemporalWorkerManagerService } from 'nestjs-temporal-core';
import { AppModule } from '@gitroom/orchestrator/app.module';
import * as dns from 'node:dns';
dns.setDefaultResultOrder('ipv4first');

// Optional self-healing (opt-in via TEMPORAL_WORKER_WATCHDOG=1).
// Der Temporal-Worker verbindet sich beim Start genau einmal; schlaegt das
// fehl, bleibt er dauerhaft inaktiv (Prozess laeuft weiter, PM2 meldet online).
// Ist ein Supervisor vorhanden (pm2-runtime/systemd), beenden wir den Prozess,
// damit er neu startet und die Verbindung erneut aufbaut.
function startWorkerWatchdog(app: INestApplication) {
  const wm = app.get(TemporalWorkerManagerService, { strict: false }) as any;
  if (!wm || typeof wm.getAllWorkers !== 'function') {
    console.warn('[temporal-watchdog] TemporalWorkerManagerService not available');
    return;
  }

  const graceMs =
    Number(process.env.TEMPORAL_WORKER_WATCHDOG_GRACE_MS) || 60_000;
  const intervalMs =
    Number(process.env.TEMPORAL_WORKER_WATCHDOG_INTERVAL_MS) || 30_000;
  const startedAt = Date.now();
  let misses = 0;

  setInterval(() => {
    // Start-Grace: nicht sofort bewerten, der Worker braucht kurz.
    if (Date.now() - startedAt < graceMs) return;

    let status: { runningWorkers?: number } | undefined;
    try {
      status = wm.getAllWorkers();
    } catch {
      return;
    }
    if (!status) return;

    if ((status.runningWorkers ?? 0) === 0) {
      misses++;
      console.error(
        `[temporal-watchdog] no running Temporal workers (${misses}/2)`
      );
      if (misses >= 2) {
        console.error(
          '[temporal-watchdog] exiting so the supervisor can restart the process'
        );
        process.exit(1);
      }
    } else {
      misses = 0;
    }
  }, intervalMs).unref();

  console.log(
    `[temporal-watchdog] enabled (interval ${intervalMs}ms, grace ${graceMs}ms)`
  );
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableShutdownHooks();
  const port = process.env.ORCHESTRATOR_PORT || 3002;
  await app.listen(port);
  console.log(`Orchestrator health check listening on port ${port}`);

  if (process.env.TEMPORAL_WORKER_WATCHDOG === '1') {
    startWorkerWatchdog(app);
  }
}

bootstrap();
