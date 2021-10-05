# The role for the Ceph Monitor and Storage
class easystack::role::ha::ceph::monitor_storage inherits ::easystack::role {

    require ::easystack::profile::network::block_ceph

    # Sync time
    include ::easystack::profile::chrony

    include ::easystack::profile::ceph::monitor_storage

    class { '::easystack::profile::netdata':
        listen_ip => ip_for_network($::easystack::config::ceph_management_network)
    }

}
