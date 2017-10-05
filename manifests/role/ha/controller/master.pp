# The role for the OpenStack master controller
class easystack::role::ha::controller::master inherits ::easystack::role {

    require ::easystack::profile::network::controller

    # Sync time
    include ::easystack::profile::chrony

    # Install certificates
    include ::easystack::profile::certificates

    # Install and configure Memcached
    include ::easystack::profile::memcached

    # Install and configure MariaDB
    class { '::easystack::profile::mariadb':
        master => true,
    }

    include ::easystack::profile::haproxy::galera

    # If there are no other servers up and we are the master, the cluster
    # needs to be bootstrapped. This happens before the service is managed
    include ::easystack::profile::mariadb::galera_bootstrap

    include ::easystack::profile::mariadb::mysqlchk

    # Setup RabbitMQ
    class { '::easystack::profile::rabbitmq':
        delete_guest_user => true,
    }

    include ::easystack::profile::rabbitmq::openstack

    # Setup corosync
    class { '::easystack::profile::corosync':
        master => true,
    }

    include ::easystack::profile::corosync::authenticate_nodes

    include ::easystack::profile::corosync::vip

    # Setup haproxy
    include ::easystack::profile::haproxy

    # Configure haproxy resources
    include ::easystack::profile::haproxy::keystone

    include ::easystack::profile::apache

    include ::easystack::profile::keystone::database

    class { '::easystack::profile::keystone':
        sync_db => true,
    }

    include ::easystack::profile::keystone::endpoint
    include ::easystack::profile::keystone::roles::admin
    include ::easystack::profile::keystone::disable_admin_token_auth

    include ::easystack::profile::glance::database

    include ::easystack::profile::glance::api::authtoken
    class { '::easystack::profile::glance::api':
        sync_db => true,
    }

    include ::easystack::profile::glance::registry::authtoken
    include ::easystack::profile::glance::registry

    include ::easystack::profile::glance::backend::nfs

    include ::easystack::profile::glance::auth

    # Setup Glance Haproxy resources
    include ::easystack::profile::haproxy::glance_api
    include ::easystack::profile::haproxy::glance_registry

    include ::easystack::profile::nova::database

    include ::easystack::profile::nova
    include ::easystack::profile::nova::cache

    include ::easystack::profile::nova::authtoken

    include ::easystack::profile::nova::auth
    include ::easystack::profile::nova::auth_placement
    include ::easystack::profile::nova::cell_v2

    class { '::easystack::profile::nova::api':
        sync_db => true,
    }

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

    include ::easystack::profile::neutron::database

    include ::easystack::profile::neutron

    include ::easystack::profile::neutron::authtoken

    class { '::easystack::profile::neutron::server':
        sync_db => true,
    }

    include ::easystack::profile::neutron::plugins::ml2

    include ::easystack::profile::neutron::auth

    include ::easystack::profile::neutron::agents::dhcp

    include ::easystack::profile::neutron::agents::ml2::linuxbridge

    include ::easystack::profile::neutron::agents::metadata

    # Setup Neutron Haproxy resources
    include ::easystack::profile::haproxy::neutron_api

    include ::easystack::profile::filebeat

}
