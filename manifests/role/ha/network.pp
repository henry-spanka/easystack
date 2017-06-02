# The role for the OpenStack network node
class easystack::role::ha::network inherits ::easystack::role {
    # Make sure the time is synced on the controller nodes

    # Sync time
    # TODO: Sync time with controller(s) instead
    include ::easystack::profile::chrony

    include ::easystack::profile::neutron
    include ::easystack::profile::neutron::authtoken

    include ::easystack::profile::neutron::plugins::ml2

    include ::easystack::profile::neutron::agents::l3
    include ::easystack::profile::neutron::agents::dhcp

    include ::easystack::profile::neutron::agents::ml2::linuxbridge

    include ::easystack::profile::neutron::agents::metadata

}
