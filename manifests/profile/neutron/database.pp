# Setup Neutron Database
class easystack::profile::neutron::database (
    String $db_neutron_password = $::easystack::config::database_neutron_password,
) {

    include easystack
    include easystack::profile::mariadb

    mysql::db { 'neutron':
        user     => 'neutron',
        password => mysql_password($db_neutron_password),
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql_user { 'neutron@%':
        ensure        => 'present',
        password_hash => mysql_password($db_neutron_password),
    }
    -> mysql_grant { 'neutron@%/neutron.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'neutron.*',
        user       => 'neutron@%',
    }

    Class['easystack::profile::neutron::database']
    -> Anchor['easystack::openstack::dbsync_2::begin']
}
