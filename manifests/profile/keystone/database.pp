# Setup Keystone Database
class easystack::profile::keystone::database (
    String $db_keystone_password = $::easystack::config::database_keystone_password,
) {

    include easystack
    include easystack::profile::mariadb

    mysql::db { 'keystone':
        user     => 'keystone',
        password => mysql_password($db_keystone_password),
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql_user { 'keystone@%':
        ensure        => 'present',
        password_hash => mysql_password($db_keystone_password),
    }
    -> mysql_grant { 'keystone@%/keystone.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'keystone.*',
        user       => 'keystone@%',
    }

    Class['easystack::profile::keystone::database']
    -> Anchor['easystack::openstack::dbsync_1::begin']
}
