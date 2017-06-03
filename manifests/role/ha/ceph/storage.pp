# The role for the Ceph Blck Storage
class easystack::role::ha::ceph::storage inherits ::easystack::role {
    # Sync time
    include ::easystack::profile::chrony

    include ::easystack::profile::ceph

    include ::easystack::profile::ceph::storage

}
