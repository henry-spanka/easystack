# Setup Neutron DHCP Agent
class easystack::profile::neutron::agents::dhcp (
    Boolean $manage = false,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::neutron

    class { '::neutron::agents::dhcp':
        interface_driver         => 'linuxbridge',
        dhcp_driver              => 'neutron.agent.linux.dhcp.Dnsmasq',
        enable_isolated_metadata => true,
        manage_service           => $manage,
        enabled                  => $manage,
    }

}
