# The role for the OpenStack compute node
class easystack::role::ha::compute inherits ::easystack::role {
    # Sync time
    # TODO: Sync time with controller(s) instead
    include ::easystack::profile::chrony

    include ::easystack::profile::nova
    include ::easystack::profile::nova::cache

    include ::easystack::profile::nova::compute
    include ::easystack::profile::nova::compute::libvirt

    include ::easystack::profile::nova::neutron
    include ::easystack::profile::nova::placement

    include ::easystack::profile::nova::authtoken

    include ::easystack::profile::neutron

    class { '::easystack::profile::neutron::agents::ml2::linuxbridge':
        local_ip                    => ip_for_network($::easystack::config::neutron_network),
        provider_interface_mappings => [],
    }

}
