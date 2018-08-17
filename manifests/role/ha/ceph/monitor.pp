# The role for the Ceph Monitor
class easystack::role::ha::ceph::monitor inherits ::easystack::role {

    require ::easystack::profile::network::mon_ceph

    # Sync time
    include ::easystack::profile::chrony

    include ::easystack::profile::ceph::monitor

    include ::easystack::profile::netdata

}
