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

# --- DDEV project name in .ddev/config.yaml ---
if [ -f ".ddev/config.yaml" ]; then
  # replace the name: line with current folder
  sed -i '' "s/^name: .*/name: ${PROJECT_NAME}/" .ddev/config.yaml 2>/dev/null || \
  sed -i "s/^name: .*/name: ${PROJECT_NAME}/" .ddev/config.yaml 2>/dev/null || true
fi

# --- make sure ports are mapped ---
if ! grep -q "web_extra_exposed_ports" .ddev/config.yaml; then
  cat >> .ddev/config.yaml <<'YAML'

web_extra_exposed_ports:
  - name: craft-vite
    container_port: 5173
    http_port: 5172
    https_port: 5173
YAML
fi

# --- (optional) turn off mutagen for stability ---
ddev config --mutagen-enabled=false >/dev/null 2>&1 || true

# --- start DDEV cleanly ---
ddev stop --unlist "${PROJECT_NAME}" >/dev/null 2>&1 || true
ddev start

# --- kill any stale vite/node inside the container ---
ddev exec pkill -f vite >/dev/null 2>&1 || true
ddev exec pkill -9 node >/dev/null 2>&1 || true

# --- PHP deps ---
ddev composer install

# --- Node deps ---
ddev npm install

# --- Ensure Craft Vite plugin installed & enabled ---
if ! ddev composer show nystudio107/craft-vite >/dev/null 2>&1; then
  ddev composer require nystudio107/craft-vite
fi
ddev craft plugin/install vite >/dev/null 2>&1 || true

# --- Security key if blank ---
if ! grep -q "^CRAFT_SECURITY_KEY=" .env || [ -z "$(grep '^CRAFT_SECURITY_KEY=' .env | cut -d= -f2)" ]; then
  ddev craft setup/security-key
fi

# --- Install or apply project config ---
# If it’s a brand-new DB, "install" will run; otherwise apply project config/migrations
if ddev craft install/can-install >/dev/null 2>&1; then
  ddev craft install
else
  ddev craft migrate/all || true
  ddev craft project-config/apply --force || true
fi

echo ""
echo "✅ Setup complete!"
echo "🔗 Site:   ${PRIMARY_URL}"
echo "🔗 Vite:   ${PRIMARY_URL}:5173"
echo "👉 Starting Vite dev server..."
echo ""

# --- start vite dev server (foreground) ---
ddev npm run dev
