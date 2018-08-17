# The role for the Ceph Monitor
class easystack::role::ha::ceph::monitor inherits ::easystack::role {

    require ::easystack::profile::network::mon_ceph

    # Sync time
    include ::easystack::profile::chrony

    include ::easystack::profile::ceph::monitor

    class { '::easystack::profile::netdata':
        listen_ip => ip_for_network($::easystack::config::ceph_management_network)
    }

}
