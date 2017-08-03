# The role for the OpenStack compute node
class easystack::role::ha::compute inherits ::easystack::role {
    # Sync time
    # TODO: Sync time with controller(s) instead
    class { '::easystack::profile::chrony':
        service_manage => true,
    }

    include ::easystack::profile::nova
    include ::easystack::profile::nova::cache

    include ::easystack::profile::nova::compute
    include ::easystack::profile::nova::compute::libvirt

    include ::easystack::profile::nova::migration::libvirt

    include ::easystack::profile::nova::neutron
    include ::easystack::profile::nova::placement

    include ::easystack::profile::nova::authtoken

    include ::easystack::profile::nova::compute::rbd

    include ::easystack::profile::neutron

    class { '::easystack::profile::neutron::agents::ml2::linuxbridge':
        manage => true,
    }

}
