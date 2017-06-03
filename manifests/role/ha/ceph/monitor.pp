# The role for the Ceph Monitor
class easystack::role::ha::ceph::monitor inherits ::easystack::role {
    # Sync time
    include ::easystack::profile::chrony

    include ::easystack::profile::ceph

    include ::easystack::profile::ceph::monitor

}
