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
  'instanceid' => 'ocm4p6ap3o4m',
  'passwordsalt' => 'iqTJAKHQTuDGS4kIECDlyidurBlsPP',
  'secret' => 't3alAVyzoja5Gf8HkaAkMDKzyY3GSkBEXyWFLqo0I7OqjU/L',
  'trusted_domains' => 
  array (
    0 => 'nextcloud.ewe-netz-backup.de',
  ),
  'trusted_proxies' => 
  array (
    0 => '10.100.0.0/16',
    1 => '127.0.0.1',
    2 => '::1',
  ),
  'datadirectory' => '/var/www/html/data',
  'dbtype' => 'mysql',
  'version' => '31.0.4.1',
  'overwrite.cli.url' => 'https://nextcloud.ewe-netz-backup.de',
  'overwriteprotocol' => 'https',
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
  'maintenance_window_start' => 1,
  'default_phone_region' => 'DE',
  'mail_smtpmode' => 'smtp',
  'mail_sendmailmode' => 'smtp',
  'mail_smtphost' => 'smtp.mail.eu-west-1.awsapps.com',
  'mail_smtpport' => '587',
  'mail_from_address' => 'lennart.schwartz',
  'mail_domain' => 'ewe-netz-backup.de',
  'mail_smtpauth' => true,
  'mail_smtpname' => 'lennart.schwartz@ewe-netz-backup.de',
  'mail_smtppassword' => 'J0n4Kape!!e25',
  'mail_smtpsecure' => 'ssl',
  'mail_smtpauthtype' => 'LOGIN',
);
