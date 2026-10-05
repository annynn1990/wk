#!/bin/bash
set -e

CONF_FILE="/var/www/html/LocalSettings.php"
SERVER="${MW_SERVER:-http://localhost:8080}"
DATABASE_URL="${DATABASE_URL:-}"

if [ -z "$DATABASE_URL" ]; then
  echo "DATABASE_URL is required for the MediaWiki installation."
  exit 1
fi

php <<'PHP'
<?php
$url = getenv('DATABASE_URL');
$server = getenv('MW_SERVER') ?: 'http://localhost:8080';
$u = parse_url($url);

if (!$u || empty($u['host']) || empty($u['user']) || empty($u['path'])) {
    fwrite(STDERR, "Invalid DATABASE_URL\n");
    exit(1);
}

parse_str($u['query'] ?? '', $query);
$dbname = ltrim($u['path'], '/');
$dbuser = $u['user'];
$dbpass = $u['pass'] ?? '';
$dbhost = $u['host'];
$dbport = (string)($u['port'] ?? 5432);
$sslmode = $query['sslmode'] ?? '';

$secret = hash('sha256', $url . '|' . $server . '|wongming-secret');
$upgrade = substr(hash('sha256', $url . '|wongming-upgrade'), 0, 32);

$cfg = "<?php\n";
$cfg .= "\$wgSitename = \"黃名帝國百科\";\n";
$cfg .= "\$wgMetaNamespace = \"黃名帝國百科\";\n";
$cfg .= "\$wgServer = " . var_export($server, true) . ";\n";
$cfg .= "\$wgScriptPath = \"\";\n";
$cfg .= "\$wgLanguageCode = \"zh-tw\";\n";
$cfg .= "\$wgLocaltimezone = \"Asia/Taipei\";\n";
$cfg .= "\$wgDBtype = \"postgres\";\n";
$cfg .= "\$wgDBserver = " . var_export($dbhost . ':' . $dbport, true) . ";\n";
$cfg .= "\$wgDBname = " . var_export($dbname, true) . ";\n";
$cfg .= "\$wgDBuser = " . var_export($dbuser, true) . ";\n";
$cfg .= "\$wgDBpassword = " . var_export($dbpass, true) . ";\n";
$cfg .= "\$wgDBprefix = \"\";\n";
$cfg .= "\$wgSecretKey = " . var_export($secret, true) . ";\n";
$cfg .= "\$wgUpgradeKey = " . var_export($upgrade, true) . ";\n";
$cfg .= "\$wgEnableUploads = true;\n";
$cfg .= "\$wgFileExtensions = array_merge(\$wgFileExtensions ?? [], ['png','gif','jpg','jpeg','webp','svg','pdf']);\n";
if ($sslmode === 'require') {
    $cfg .= "\$wgDBoptions = ['sslmode' => 'require'];\n";
}
file_put_contents('/var/www/html/LocalSettings.php', $cfg);
?>
PHP

export MW_DBHOST MW_DBPORT MW_DBUSER MW_DBPASS MW_DBNAME
eval "$(php -r '
  $u = parse_url(getenv("DATABASE_URL"));
  echo "export MW_DBHOST=" . escapeshellarg($u["host"] ?? "") . "\n";
  echo "export MW_DBPORT=" . escapeshellarg((string)($u["port"] ?? 5432)) . "\n";
  echo "export MW_DBUSER=" . escapeshellarg($u["user"] ?? "") . "\n";
  echo "export MW_DBPASS=" . escapeshellarg($u["pass"] ?? "") . "\n";
  echo "export MW_DBNAME=" . escapeshellarg(ltrim($u["path"] ?? "", "/")) . "\n";
')"

INSTALLED="$(php -r '
  try {
    $pdo = new PDO(
      "pgsql:host=" . getenv("MW_DBHOST") . ";port=" . getenv("MW_DBPORT") . ";dbname=" . getenv("MW_DBNAME"),
      getenv("MW_DBUSER"),
      getenv("MW_DBPASS"),
      [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    $pdo->query("SELECT 1 FROM site_stats LIMIT 1");
    echo "yes";
  } catch (Throwable $e) {
    echo "no";
  }
')"

if [ "$INSTALLED" != "yes" ]; then
  : "${MW_ADMIN_PASS:?MW_ADMIN_PASS is required for first installation}"
  php maintenance/run.php install     --dbtype=postgres     --dbserver="${MW_DBHOST}:${MW_DBPORT}"     --dbuser="${MW_DBUSER}"     --dbpass="${MW_DBPASS}"     --dbname="${MW_DBNAME}"     --confpath="/var/www/html"     --server="$SERVER"     --scriptpath=""     --lang=zh-tw     --pass="$MW_ADMIN_PASS"     "黃名帝國百科"     "${MW_ADMIN_USER:-admin}"
fi

exec apache2-foreground
