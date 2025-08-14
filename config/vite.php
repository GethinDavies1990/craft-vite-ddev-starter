<?php
use craft\helpers\App;

return [
    'useDevServer' => App::env('CRAFT_ENVIRONMENT') === 'dev',
    'manifestPath' => '@webroot/dist/.vite/manifest.json',

    // Browser should fetch dev assets from HTTPS :5173
    'devServerPublic' => App::env('PRIMARY_SITE_URL') . ':5173',

    'serverPublic' => App::env('PRIMARY_SITE_URL') . '/dist/',
    'errorEntry' => '',
    'cacheKeySuffix' => '',

    // Not used when checkDevServer=false, but fine to leave:
    'devServerInternal' => 'http://localhost:5173',

    'checkDevServer' => false, // don't ping; just use the dev server
    'includeReactRefreshShim' => false,
    'includeModulePreloadShim' => true,
    'criticalPath' => '@webroot/dist/criticalcss',
    'criticalSuffix' => '_critical.min.css',
    'includeScriptOnloadHandler' => true,
];
