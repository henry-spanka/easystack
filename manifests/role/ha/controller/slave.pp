# The role for the OpenStack slave controller(s)
class easystack::role::ha::controller::slave inherits ::easystack::role {
    # Sync time
    include ::easystack::profile::chrony

    # Install and configure Memcached
    include ::easystack::profile::memcached

    # Install and configure MariaDB
    class { '::easystack::profile::mariadb':
        master => false,
    }

    include ::easystack::profile::mariadb::mysqlchk

    # Setup RabbitMQ
    include ::easystack::profile::rabbitmq

    # Setup corosync
    class { '::easystack::profile::corosync':
        master => false,
    }

    # Make sure we authenticate before starting mysql
    # The master has already initialized the database when
    # corosync and pcsd is ready so it's safe to start mysql
    Exec['reauthenticate-across-all-nodes'] -> Service['mysqld']

    # Install Haproxy and Apache before autenticating as otherwise a warning message
    # will be displayed that the services can not be found by pacemaker
    Package['haproxy'] -> Class['::easystack::profile::corosync']
    Package['httpd'] -> Class['::easystack::profile::corosync']
    Service['mysqld'] -> Service['haproxy']
    Service['mysqld'] -> Service['httpd']

    # Setup haproxy
    include ::easystack::profile::haproxy

    # Configure haproxy resources
    include ::easystack::profile::haproxy::keystone
    include ::easystack::profile::haproxy::galera

    # Setup apache
    class { 'apache':
        default_vhost => false,
        servername    => $::fqdn,
    }

    class { '::easystack::profile::keystone':
        master => false,
    }

    # Configure glance
    class { '::easystack::profile::glance':
        master => false,
    }

    # Setup Glance Haproxy resources
    include ::easystack::profile::haproxy::glance_api
    include ::easystack::profile::haproxy::glance_registry

}
