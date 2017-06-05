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
    Service['haproxy'] -> Package['corosync']

    # Install Haproxy and Apache before autenticating as otherwise a warning message
    # will be displayed that the services can not be found by pacemaker
    Package['haproxy'] -> Class['::easystack::profile::corosync']
    Package['httpd'] -> Class['::easystack::profile::corosync']
    Service['haproxy'] -> Service['mysqld']
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

    include ::easystack::profile::glance::backend::rbd

    # Setup Glance Haproxy resources
    include ::easystack::profile::haproxy::glance_api
    include ::easystack::profile::haproxy::glance_registry

    # Configure Compute service Nova on controller node
    include ::easystack::profile::nova
    include ::easystack::profile::nova::cache

    include ::easystack::profile::nova::authtoken

    include ::easystack::profile::nova::api
    include ::easystack::profile::nova::placement

    include ::easystack::profile::nova::conductor
    include ::easystack::profile::nova::consoleauth
    include ::easystack::profile::nova::vncproxy
    include ::easystack::profile::nova::scheduler

    include ::easystack::profile::nova::neutron

    Service['mysqld'] -> Service['nova-api']
    Service['mysqld'] -> Service['nova-conductor']
    Service['mysqld'] -> Service['nova-consoleauth']
    Service['mysqld'] -> Service['nova-vncproxy']
    Service['mysqld'] -> Service['nova-scheduler']

    # Setup Glance Haproxy resources
    include ::easystack::profile::haproxy::nova_compute_api
    include ::easystack::profile::haproxy::nova_metadata_api
    include ::easystack::profile::haproxy::nova_placement_api
    include ::easystack::profile::haproxy::nova_vncproxy

    # Setup Horizon
    include ::easystack::profile::horizon

    # Setup Horizon Haproxy resource
    include ::easystack::profile::haproxy::horizon

    include ::easystack::profile::neutron

    include ::easystack::profile::neutron::authtoken

    class { '::easystack::profile::neutron::server':
        sync_db => false,
    }

    include ::easystack::profile::neutron::plugins::ml2

    Service['mysqld'] -> Service['neutron-server']

    # Setup Neutron Haproxy resources
    include ::easystack::profile::haproxy::neutron_api

}
