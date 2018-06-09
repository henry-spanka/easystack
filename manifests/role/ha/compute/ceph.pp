# The role for the OpenStack compute node with Ceph
class easystack::role::ha::compute::ceph inherits ::easystack::role {

    require ::easystack::profile::network::compute_ceph

    # Sync time
    # TODO: Sync time with controller(s) instead
    include ::easystack::profile::chrony

    # Install certificates
    include ::easystack::profile::certificates

    include ::easystack::profile::nova
    include ::easystack::profile::nova::cache

    include ::easystack::profile::nova::compute
    include ::easystack::profile::nova::compute::libvirt
    include ::easystack::profile::nova::compute::rbd
    include ::easystack::profile::nova::compute::ssh

    include ::easystack::profile::ksm

    include ::easystack::profile::nova::migration::libvirt

    include ::easystack::profile::nova::neutron
    include ::easystack::profile::nova::placement

    include ::easystack::profile::nova::authtoken

    include ::easystack::profile::neutron

    include ::easystack::profile::neutron::agents::ml2::linuxbridge

    include ::easystack::profile::netdata

}
