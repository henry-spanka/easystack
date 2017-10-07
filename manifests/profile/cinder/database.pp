# Setup Cinder Database
class easystack::profile::cinder::database (
    String $db_cinder_password = $::easystack::config::database_cinder_password,
) {

    include easystack
    include easystack::profile::mariadb

    mysql::db { 'cinder':
        user     => 'cinder',
        password => mysql_password($db_cinder_password),
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql_user { 'cinder@%':
        ensure        => 'present',
        password_hash => mysql_password($db_cinder_password),
    }
    -> mysql_grant { 'cinder@%/cinder.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'cinder.*',
        user       => 'cinder@%',
    }

    Class['easystack::profile::cinder::database']
    -> Anchor['easystack::openstack::dbsync_2::begin']
}
