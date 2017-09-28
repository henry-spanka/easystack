# Setup Glance Database
class easystack::profile::glance::database (
    String $db_glance_password = $::easystack::config::database_glance_password,
) {

    include easystack
    include easystack::profile::mariadb

    mysql::db { 'glance':
        user     => 'glance',
        password => mysql_password($db_glance_password),
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql_user { 'glance@%':
        ensure        => 'present',
        password_hash => mysql_password($db_glance_password),
    }
    -> mysql_grant { 'glance@%/glance.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'glance.*',
        user       => 'glance@%',
    }

    Class['easystack::profile::glance::database']
    -> Anchor['easystack::openstack::dbsync_2::begin']
}
