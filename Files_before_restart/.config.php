<?php
$CONFIG = array (
  'htaccess.RewriteBase' => '/',
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'apps_paths' => 
  array (
    0 => 
    array (
      'path' => '/var/www/html/apps',
      'url' => '/apps',
      'writable' => false,
    ),
    1 => 
    array (
      'path' => '/var/www/html/custom_apps',
      'url' => '/custom_apps',
      'writable' => true,
    ),
  ),
  'upgrade.disable-web' => true,
  'instanceid' => 'ocoqsejg791i',
  'passwordsalt' => 'X00u8DAAYpezvrZaWE2Kyj1Y571WkV',
  'secret' => '9S/NvyMwtW0hxPZTXzQolsKvIPc/xy56lwBSVgzbt3GDA/KI',
  'trusted_domains' => 
  array (
    0 => 'nextcloud.ewe-netz-backup.de',
  ),
  'datadirectory' => '/var/www/html/data',
  'dbtype' => 'mysql',
  'version' => '31.0.4.1',
  'overwrite.cli.url' => 'https://nextcloud.ewe-netz-backup.de',
  'dbname' => 'nextcloud',
  'dbhost' => 'nextcloud-mariadb',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => 'nextcloud',
  'dbpassword' => 'nextcloud123',
  'installed' => true,
  'app_install_overwrite' => 
  array (
    0 => 'snappymail',
  ),
  'mail_smtpmode' => 'smtp',
  'mail_smtpsecure' => 'ssl',
  'mail_sendmailmode' => 'smtp',
  'trusted_proxies' => 
  array (
    0 => '10.100.168.193',
    1 => '10.100.0.0/16',
    2 => '127.0.0.1',
  ),
  'forwarded_for_headers' => 
  array (
    0 => 'HTTP_X_FORWARDED_FOR',
  ),
  'overwriteprotocol' => 'https',
  'default_phone_region' => 'DE',
  'maintenance' => false,
  'maintenance_window_start' => 1,
);
