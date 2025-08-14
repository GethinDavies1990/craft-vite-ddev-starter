#!/bin/bash
set -e

# Step 1: Copy .env
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo ".env file created from .env.example"
fi

# Step 2: Prompt for site URL
DEFAULT_URL="https://$(basename "$PWD").ddev.site"
read -p "Enter PRIMARY_SITE_URL [${DEFAULT_URL}]: " SITE_URL
SITE_URL=${SITE_URL:-$DEFAULT_URL}
sed -i '' "s|^PRIMARY_SITE_URL=.*|PRIMARY_SITE_URL=${SITE_URL}|" .env

# Step 3: Update DDEV project name
PROJECT_NAME=$(basename "$PWD")
sed -i '' "s/^name: .*/name: ${PROJECT_NAME}/" .ddev/config.yaml

# Step 4: Start DDEV
ddev start

# Step 5: Install PHP deps
ddev composer install

# Step 6: Install JS deps
ddev npm install

# Step 7: Generate security key if missing
if ! grep -q "CRAFT_SECURITY_KEY" .env || [ -z "$(grep CRAFT_SECURITY_KEY .env | cut -d '=' -f2)" ]; then
    ddev craft setup/security-key
fi

# Step 8: Install Craft (if DB empty)
if ! ddev craft info >/dev/null 2>&1; then
    echo "Installing Craft CMS..."
    ddev craft install
else
    echo "Craft already installed. Running migrations..."
    ddev craft migrate/all || true
    ddev craft project-config/apply --force || true
fi

# Step 9: Start Vite dev server
ddev npm run dev

