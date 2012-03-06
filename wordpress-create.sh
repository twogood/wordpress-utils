#!/bin/sh
DB_NAME=$1
HOSTNAME=$2
DB_USER=$DB_NAME
DB_PASSWORD=`pwgen -1s`

if [ -z "$HOSTNAME" ]; then
  cat <<EOF
Syntax:
  $0 DATABASE-NAME SITE-NAME
EOF
  exit 1
fi


set -e

mysqladmin -uroot -p create $DB_NAME || true
mysql -uroot -p <<EOF
grant all privileges on $DB_NAME.* to $DB_USER@localhost identified by '$DB_PASSWORD';
EOF

sudo tee /etc/wordpress/config-$HOSTNAME.php >/dev/null <<EOF
<?php

define('DB_NAME', '$DB_NAME');
define('DB_USER', '$DB_USER');
define('DB_PASSWORD', '$DB_PASSWORD');
define('DB_HOST', 'localhost');
define ('WPLANG', 'sv_SE');

\$table_prefix  = 'wp_';

\$server = DB_HOST;
\$loginsql = DB_USER;
\$passsql = DB_PASSWORD;
\$base = DB_NAME;

?>
EOF

SITE_NAME=`echo $HOSTNAME | tr . _`
sudo tee /etc/apache2/sites-available/$SITE_NAME >/dev/null <<EOF
<VirtualHost *>
  DocumentRoot /usr/share/wordpress
  ServerName $HOSTNAME
  ServerAlias www.$HOSTNAME
  ErrorLog /var/log/apache2/$HOSTNAME-error_log
  CustomLog /var/log/apache2/$HOSTNAME-access_log combined env=!dontlog

  Include local/wordpress.conf
</VirtualHost>
EOF

sudo a2ensite $SITE_NAME

