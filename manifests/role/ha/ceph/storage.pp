# The role for the Ceph Blck Storage
class easystack::role::ha::ceph::storage inherits ::easystack::role {

    require ::easystack::profile::network::block_ceph

    # Sync time
    include ::easystack::profile::chrony

    include ::easystack::profile::ceph::storage

}
