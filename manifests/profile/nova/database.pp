# Setup Nova Database
class easystack::profile::nova::database (
    String $db_nova_password = $::easystack::config::database_nova_password,
) {

    include easystack
    include easystack::profile::mariadb

    # Configure nova mySQL databases
    mysql::db { 'nova_api':
        user     => 'nova',
        password => $db_nova_password,
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql::db { 'nova':
        user     => 'nova',
        password => $db_nova_password,
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql::db { 'nova_cell0':
        user     => 'nova',
        password => $db_nova_password,
        host     => 'localhost',
        grant    => ['ALL'],
    }
    -> mysql_user { 'nova@%':
        ensure        => 'present',
        password_hash => mysql_password($db_nova_password),
    }
    -> mysql_grant { 'nova@%/nova_api.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'nova_api.*',
        user       => 'nova@%',
    }
    -> mysql_grant { 'nova@%/nova.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'nova.*',
        user       => 'nova@%',
    }
    -> mysql_grant { 'nova@%/nova_cell0.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'nova_cell0.*',
        user       => 'nova@%',
    }

    Class['easystack::profile::nova::database']
    -> Anchor['easystack::openstack::dbsync_1::begin']
}
