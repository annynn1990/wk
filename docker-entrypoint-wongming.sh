#!/bin/bash
set -e

CONF_FILE="/var/www/html/LocalSettings.php"
SERVER="${MW_SERVER:-http://localhost:8080}"

mkdir -p /var/www/html/images
chown -R www-data:www-data /var/www/html/images

: "${DATABASE_URL:?DATABASE_URL is required}"

# Render's connectionString is a libpq key=value string.
: "${DATABASE_URL:?DATABASE_URL is required}"

readarray -t DB_PARTS < <(DATABASE_URL="$DATABASE_URL" php -r '
$s = getenv("DATABASE_URL");
$p = [];
preg_match_all("/(?:^| )([A-Za-z_]+)=((?:\\\\.|[^ ])*)/", $s, $m, PREG_SET_ORDER);
foreach ($m as $x) { $p[$x[1]] = str_replace("\\\\ ", " ", $x[2]); }
foreach (["host","port","user","password","dbname"] as $k) {
    if (!isset($p[$k]) || $p[$k] === "") { fwrite(STDERR, "Missing PostgreSQL field: $k\n"); exit(1); }
    echo $p[$k], PHP_EOL;
}
')

DB_HOST="${DB_PARTS[0]}"
DB_PORT="${DB_PARTS[1]}"
DB_USER="${DB_PARTS[2]}"
DB_PASS="${DB_PARTS[3]}"
DB_NAME="${DB_PARTS[4]}"

if php -r '
$dsn = "pgsql:host=" . getenv("DB_HOST") . ";port=" . getenv("DB_PORT") . ";dbname=" . getenv("DB_NAME");
try {
    $pdo = new PDO($dsn, getenv("DB_USER"), getenv("DB_PASS"), [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 5,
    ]);
    $stmt = $pdo->query("SELECT to_regclass(\047public.page\047)");
    exit(($stmt->fetchColumn() !== null) ? 0 : 2);
} catch (Throwable $e) {
    fwrite(STDERR, "PostgreSQL connection check failed: " . $e->getMessage() . PHP_EOL);
    exit(3);
}
'; then
  # Persistent PostgreSQL already contains the MediaWiki schema.
  export DB_HOST DB_PORT DB_USER DB_PASS DB_NAME
  export MW_SERVER="$SERVER"
  export MW_SECRET_KEY="${MW_SECRET_KEY:-wongming-empire-mediawiki-secret-2026}"
  export MW_UPGRADE_KEY="${MW_UPGRADE_KEY:-wongming-upgrade-2026}"
  php <<'PHP'
<?php
function ps($v) {
    return "'" . str_replace(["\\", "'"], ["\\\\", "\\'"], (string)$v) . "'";
}
$server = getenv("MW_SERVER");
$secret = getenv("MW_SECRET_KEY");
$upgrade = getenv("MW_UPGRADE_KEY");
$out = "<?php\n";
$out .= '$wgSitename = ' . ps("黃名帝國百科") . ";\n";
$out .= '$wgMetaNamespace = ' . ps("黃名帝國百科") . ";\n";
$out .= '$wgServer = ' . ps($server) . ";\n";
$out .= '$wgScriptPath = "";\n';
$out .= '$wgLanguageCode = ' . ps("zh-tw") . ";\n";
$out .= '$wgLocaltimezone = ' . ps("Asia/Taipei") . ";\n";
$out .= '$wgDBtype = "postgres";' . "\n";
$out .= '$wgDBserver = ' . ps(getenv("DB_HOST") . ":" . getenv("DB_PORT")) . ";\n";
$out .= '$wgDBuser = ' . ps(getenv("DB_USER")) . ";\n";
$out .= '$wgDBpassword = ' . ps(getenv("DB_PASS")) . ";\n";
$out .= '$wgDBname = ' . ps(getenv("DB_NAME")) . ";\n";
$out .= '$wgSecretKey = ' . ps($secret) . ";\n";
$out .= '$wgUpgradeKey = ' . ps($upgrade) . ";\n";
$out .= '$wgEnableUploads = true;' . "\n";
file_put_contents("/var/www/html/LocalSettings.php", $out);
PHP

  chown www-data:www-data "$CONF_FILE"
  php maintenance/run.php update --quick
else
  rm -f "$CONF_FILE"
  : "${MW_ADMIN_PASS:?MW_ADMIN_PASS is required for first installation}"
  php maintenance/run.php install     --dbtype=postgres     --dbserver="$DB_HOST:$DB_PORT"     --dbuser="$DB_USER"     --dbpass="$DB_PASS"     --dbname="$DB_NAME"     --confpath="/var/www/html"     --server="$SERVER"     --scriptpath=""     --lang=zh-tw     --pass="$MW_ADMIN_PASS"     "黃名帝國百科"     "${MW_ADMIN_USER:-admin}"
fi

exec apache2-foreground
