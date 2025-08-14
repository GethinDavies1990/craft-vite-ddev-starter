Craft Vite DDEV Starter

This is a Craft CMS starter kit using Vite for frontend builds and DDEV for local development.

It includes a one-command setup script so a fresh clone boots the site, installs Craft (if needed), and starts Vite automatically.

🚀 Quick Start (fresh clone)

Clone the repo

git clone <repo-url> my-project
cd my-project

Run the setup script

sh bin/setup.sh

The script will:

Create .env (from .env.example or defaults)

Set the DDEV project name & expose Vite ports

Start DDEV containers

Install Composer & Node dependencies

Install Craft CMS (if the DB is empty), or apply project config/migrations

Start the Vite dev server

Open your site

Craft CMS: https://<folder-name>.ddev.site/admin

Vite Dev Server: https://<folder-name>.ddev.site:5173

The hostname is derived from your folder name automatically.

🔑 Default Craft admin (auto-install)
Username: admin
Password: admin1234
Email: admin@example.com

Change these after your first login.
They’re set in bin/setup.sh under the ddev craft install command.

🧰 What’s included

Craft CMS 5

Vite (+ HMR) configured for DDEV

Auto URL/HMR host detection (no hard-coded hostnames)

nystudio107/craft-vite plugin pre-installed

One-command bootstrap script: bin/setup.sh

🛠 Useful commands

Run inside the project folder:

Command Description
ddev start Start DDEV project
ddev stop Stop DDEV project
ddev ssh Shell into the web container
ddev composer install Install PHP deps
ddev npm install Install Node deps
ddev npm run dev Start Vite dev server
ddev craft migrate/all Run pending migrations
ddev craft project-config/apply --force Apply project config
ddev exec pkill -f vite Kill stale Vite processes in the container
⚠️ Common issues & fixes

Port 5173 already in use

ddev exec pkill -f vite || true
ddev exec pkill -9 node || true
ddev restart

DDEV project name collision / stale entry

ddev stop --unlist <old-name>
ddev restart

Still seeing built /dist files instead of HMR

Ensure .env has CRAFT_ENVIRONMENT=dev.

Ensure craft/config/vite.php has 'useDevServer' => true in dev.

In DevTools → Network, your JS should load from :5173, not /dist/app-\*.js.

📁 Project structure (highlights)

bin/setup.sh – one-command bootstrap (creates .env, starts DDEV, installs Craft, starts Vite)

.ddev/config.yaml – DDEV config (exposes Vite on 5173)

craft/config/vite.php – Craft Vite plugin config

vite.config.ts – Vite config (auto-detects DDEV URL)

templates/ – Craft templates

src/ – Frontend source (src/js/app.js, etc.)

web/ – Public web root (build output to web/dist)

🧹 Resetting everything (clean slate)

If you need to nuke and re-create locally:

ddev delete --omit-snapshot
docker system prune -f --volumes
git clean -fdX # CAUTION: removes untracked/ignored files
sh bin/setup.sh

👥 New developer prerequisites

Docker Desktop

DDEV

Then:

git clone <repo-url> my-project
cd my-project
sh bin/setup.sh

Login to Craft with admin / admin1234, then change credentials.
