#!/bin/sh

# ENV
export DOMAIN

DOMAIN=${DOMAIN:-$(hostname --domain)}

if [ -z "$DBPASS" ]; then
  echo "Mariadb database password must be set !"
  exit 1
fi

# Set permissions
chown -R $UID:$GID /postfixadmin /etc/nginx /etc/php7 /var/log /var/lib/nginx /tmp /etc/s6.d

# Local postfixadmin configuration file
cat > /postfixadmin/config.local.php <<EOF
<?php

\$CONF['configured'] = true;

\$CONF['database_type'] = 'mysqli';
\$CONF['database_host'] = '${DBHOST}';
\$CONF['database_user'] = '${DBUSER}';
\$CONF['database_password'] = '${DBPASS}';
\$CONF['database_name'] = '${DBNAME}';

\$CONF['encrypt'] = 'dovecot:SHA512-CRYPT';
\$CONF['dovecotpw'] = "/usr/bin/doveadm pw";

\$CONF['smtp_server'] = '${SMTPHOST}';
\$CONF['domain_path'] = 'YES';
\$CONF['domain_in_mailbox'] = 'NO';
\$CONF['fetchmail'] = 'NO';

\$CONF['admin_email'] = 'admin@${DOMAIN}';
\$CONF['footer_text'] = 'Return to ${DOMAIN}';
\$CONF['footer_link'] = 'http://${DOMAIN}';
\$CONF['default_aliases'] = array (
  'abuse'      => 'abuse@${DOMAIN}',
  'hostmaster' => 'hostmaster@${DOMAIN}',
  'postmaster' => 'postmaster@${DOMAIN}',
  'webmaster'  => 'webmaster@${DOMAIN}'
);

// Default Domain Values
// Specify your default values below. Quota in MB.
\$CONF['maxquota'] = '10';
\$CONF['domain_quota_default'] = '2048';

// When you want to enforce quota for your mailbox users set this to 'YES'.
\$CONF['quota'] = 'NO';

// If you want to enforce domain-level quotas set this to 'YES'.
\$CONF['domain_quota'] = 'NO';

// You can either use '1024000' or '1048576'
\$CONF['quota_multiplier'] = '1024000';

// Show used quotas from Dovecot dictionary backend in virtual
// mailbox listing.
// See: http://wiki.dovecot.org/Quota/Dict
\$CONF['used_quotas'] = 'YES';

// if you use dovecot >= 1.2, set this to yes.
// Note about dovecot config: table "quota" is for 1.0 & 1.1, table "quota2" is for dovecot 1.2 and newer
\$CONF['new_quota_table'] = 'YES';
?>
EOF

# RUN !
exec su-exec $UID:$GID /bin/s6-svscan /etc/s6.d
