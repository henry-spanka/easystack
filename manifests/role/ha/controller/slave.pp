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

}
