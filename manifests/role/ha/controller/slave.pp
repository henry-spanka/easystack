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

    include easystack::profile::corosync::authenticate_nodes

    # Setup haproxy
    include ::easystack::profile::haproxy

    # Configure haproxy resources
    include ::easystack::profile::haproxy::keystone

    include ::easystack::profile::apache

    class { '::easystack::profile::keystone':
        sync_db => false,
    }

    include ::easystack::profile::keystone::disable_admin_token_auth

    # Configure glance
    include ::easystack::profile::glance

    include ::easystack::profile::glance::api::authtoken
    include ::easystack::profile::glance::api

    include ::easystack::profile::glance::registry::authtoken
    include ::easystack::profile::glance::registry

    include ::easystack::profile::glance::backend::nfs

    # Setup Glance Haproxy resources
    include ::easystack::profile::haproxy::glance_api
    include ::easystack::profile::haproxy::glance_registry

    # Configure Compute service Nova on controller node
    include ::easystack::profile::nova
    include ::easystack::profile::nova::cache

    include ::easystack::profile::nova::authtoken

    include ::easystack::profile::nova::api
    include ::easystack::profile::nova::placement_api

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

}
