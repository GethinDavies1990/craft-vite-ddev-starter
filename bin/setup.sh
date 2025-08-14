#!/bin/bash
set -e

PROJECT_NAME=$(basename "$PWD")
PRIMARY_URL="https://${PROJECT_NAME}.ddev.site"

echo "🚀 Setting up ${PROJECT_NAME} ..."

# --- .env: create if missing (no prompts) ---
if [ ! -f ".env" ]; then
  if [ -f ".env.example" ]; then
    cp .env.example .env
    echo "PRIMARY_SITE_URL=${PRIMARY_URL}" > .env.tmp
    # keep any existing keys from .env.example (except PRIMARY_SITE_URL which we set)
    grep -v '^PRIMARY_SITE_URL=' .env >> .env.tmp || true
    mv .env.tmp .env
    echo "✅ Created .env (PRIMARY_SITE_URL=${PRIMARY_URL})"
  else
    cat > .env <<EOF
CRAFT_ENVIRONMENT=dev
PRIMARY_SITE_URL=${PRIMARY_URL}
CRAFT_DB_DRIVER=mysql
CRAFT_DB_SERVER=db
CRAFT_DB_PORT=3306
CRAFT_DB_DATABASE=db
CRAFT_DB_USER=db
CRAFT_DB_PASSWORD=db
CRAFT_SECURITY_KEY=
CRAFT_DEV_MODE=true
CRAFT_ALLOW_ADMIN_CHANGES=true
CRAFT_DISALLOW_ROBOTS=true
EOF
    echo "✅ Created .env from defaults"
  fi
fi

# --- Update DDEV project name in config.yaml ---
if [ -f ".ddev/config.yaml" ]; then
  sed -i '' "s/^name: .*/name: ${PROJECT_NAME}/" .ddev/config.yaml 2>/dev/null || \
  sed -i "s/^name: .*/name: ${PROJECT_NAME}/" .ddev/config.yaml 2>/dev/null || true
fi

# --- Make sure Vite ports are mapped ---
if ! grep -q "web_extra_exposed_ports" .ddev/config.yaml; then
  cat >> .ddev/config.yaml <<'YAML'

web_extra_exposed_ports:
  - name: craft-vite
    container_port: 5173
    http_port: 5172
    https_port: 5173
YAML
fi

# --- Disable Mutagen for stability (optional) ---
ddev config --mutagen-enabled=false >/dev/null 2>&1 || true

# --- Start DDEV cleanly ---
ddev stop --unlist "${PROJECT_NAME}" >/dev/null 2>&1 || true
ddev start

# --- Kill any stale vite/node processes inside container ---
ddev exec pkill -f vite >/dev/null 2>&1 || true
ddev exec pkill -9 node >/dev/null 2>&1 || true

# --- Install PHP deps ---
ddev composer install

# --- Install Node deps ---
ddev npm install

# --- Ensure Craft Vite plugin is installed ---
if ! ddev composer show nystudio107/craft-vite >/dev/null 2>&1; then
  ddev composer require nystudio107/craft-vite
fi
ddev craft plugin/install vite >/dev/null 2>&1 || true

# --- Ensure Security Key exists ---
if ! grep -q "^CRAFT_SECURITY_KEY=" .env || [ -z "$(grep '^CRAFT_SECURITY_KEY=' .env | cut -d= -f2)" ]; then
  ddev craft setup/security-key
fi

# --- Install or apply migrations/config ---
if ddev craft install/can-install >/dev/null 2>&1; then
  echo "💾 Fresh DB detected — installing Craft..."
  ddev craft install \
    --site-name="${PROJECT_NAME}" \
    --site-url="${PRIMARY_URL}" \
    --username=admin \
    --email=admin@example.com \
    --password=admin1234
else
  echo "🔄 Applying pending migrations & project config..."
  ddev craft migrate/all || true
  ddev craft project-config/apply --force || true
fi

echo ""
echo "✅ Setup complete!"
echo "🔗 Site:   ${PRIMARY_URL}"
echo "🔗 Vite:   ${PRIMARY_URL}:5173"
echo "👉 Starting Vite dev server..."
echo ""

# --- Start Vite dev server in foreground ---
ddev npm run dev
