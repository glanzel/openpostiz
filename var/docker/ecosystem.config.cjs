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
