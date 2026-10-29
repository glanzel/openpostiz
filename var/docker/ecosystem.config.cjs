// PM2-Ecosystem fuer den slim-Entrypoint.
// Startet die drei Prozesse direkt (ohne "pnpm start"/dotenv-Wrapper).
module.exports = {
  apps: [
    {
      name: 'backend',
      cwd: '/app/apps/backend',
      script: './dist/apps/backend/src/main.js',
      interpreter: 'node',
      node_args: '--experimental-require-module',
      env: { NODE_ENV: 'production' },
    },
    {
      name: 'orchestrator',
      cwd: '/app/apps/orchestrator',
      script: './dist/apps/orchestrator/src/main.js',
      interpreter: 'node',
      node_args: '--experimental-require-module',
      env: { NODE_ENV: 'production' },
      // Der Watchdog (TEMPORAL_WORKER_WATCHDOG=1) beendet den Prozess, wenn
      // kein Temporal-Worker laeuft. PM2 startet ihn dann neu (mit Backoff).
      restart_delay: 5000,
      exp_backoff_restart_delay: 100,
    },
    {
      name: 'frontend',
      cwd: '/app/apps/frontend',
      script: '/app/node_modules/next/dist/bin/next',
      args: 'start -p 4200',
      interpreter: 'node',
      env: { NODE_ENV: 'production' },
    },
  ],
};
