#!/bin/sh
set -e

cd /var/www/html

if [ -n "$RENDER_EXTERNAL_URL" ]; then
    export APP_URL="$RENDER_EXTERNAL_URL"
fi

if [ -z "$APP_KEY" ]; then
    APP_KEY="base64:$(php -r 'echo base64_encode(random_bytes(32));')"
    export APP_KEY
elif [ "${APP_KEY#base64:}" = "$APP_KEY" ]; then
    APP_KEY="base64:$APP_KEY"
    export APP_KEY
fi

php artisan storage:link --force >/dev/null 2>&1 || true
php artisan migrate --force --no-interaction

php artisan config:cache >/dev/null 2>&1 || true
php artisan route:cache >/dev/null 2>&1 || true
php artisan view:cache >/dev/null 2>&1 || true

exec php artisan serve --host=0.0.0.0 --port="${PORT:-8080}"
