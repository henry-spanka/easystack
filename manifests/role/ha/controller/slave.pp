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
    Service['haproxy'] -> Package['corosync']

    # Install Haproxy and Apache before autenticating as otherwise a warning message
    # will be displayed that the services can not be found by pacemaker
    Package['haproxy'] -> Class['::easystack::profile::corosync']
    Package['httpd'] -> Class['::easystack::profile::corosync']

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
    include ::easystack::profile::glance

    include ::easystack::profile::glance::api::authtoken
    include ::easystack::profile::glance::api

    include ::easystack::profile::glance::registry::authtoken
    include ::easystack::profile::glance::registry

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

    include ::easystack::profile::neutron::agents::dhcp

    include ::easystack::profile::neutron::agents::ml2::linuxbridge

    include ::easystack::profile::neutron::agents::metadata

    # Setup Neutron Haproxy resources
    include ::easystack::profile::haproxy::neutron_api

    # Setup Cinder
    include ::easystack::profile::cinder
    include ::easystack::profile::cinder::authtoken

    class { '::easystack::profile::cinder::api':
        sync_db => false,
    }

    include ::easystack::profile::cinder::scheduler
    include ::easystack::profile::cinder::volume

    include ::easystack::profile::cinder::backends

    include ::easystack::profile::cinder::backends::ceph

    include ::easystack::profile::haproxy::cinder_api

}
