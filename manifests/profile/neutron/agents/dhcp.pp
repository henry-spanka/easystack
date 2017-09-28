# Setup Neutron DHCP Agent
class easystack::profile::neutron::agents::dhcp {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::neutron

    class { '::neutron::agents::dhcp':
        interface_driver         => 'linuxbridge',
        dhcp_driver              => 'neutron.agent.linux.dhcp.Dnsmasq',
        enable_isolated_metadata => true,
    }

    firewalld_service { 'Allow dhcp requests to neutron dhcp agent':
        ensure  => present,
        service => 'dhcp',
        zone    => 'public',
        tag     => 'neutron-firewall',
    }

}
