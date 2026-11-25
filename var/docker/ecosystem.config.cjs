// PM2 ecosystem for the slim runtime image.
// Starts the three node processes directly instead of going through
// "pnpm run pm2" -> "pnpm run pm2-run" -> "pm2 start pnpm -- start".
module.exports = {
  apps: [
    {
      name: 'backend',
      cwd: '/app/apps/backend',
      script: './dist/apps/backend/src/main.js',
      interpreter: 'node',
      node_args: '--experimental-require-module',
      env: {
        NODE_ENV: 'production',
      },
      time: true,
      merge_logs: true,
    },
    {
      name: 'orchestrator',
      cwd: '/app/apps/orchestrator',
      script: './dist/apps/orchestrator/src/main.js',
      interpreter: 'node',
      node_args: '--experimental-require-module',
      env: {
        NODE_ENV: 'production',
      },
      time: true,
      merge_logs: true,
    },
    {
      name: 'frontend',
      cwd: '/app/apps/frontend',
      script: '/app/node_modules/next/dist/bin/next',
      args: 'start -p 4200',
      interpreter: 'node',
      env: {
        NODE_ENV: 'production',
      },
      time: true,
      merge_logs: true,
    },
  ],
};
