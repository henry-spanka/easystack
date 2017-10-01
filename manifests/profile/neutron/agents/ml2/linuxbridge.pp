# Setup Neutron Linuxbridge ML2 Agent
class easystack::profile::neutron::agents::ml2::linuxbridge (
    Array $provider_interface_mappings = $::easystack::config::provider_interface_mappings,
    String $firewall_driver            = 'neutron.agent.linux.iptables_firewall.IptablesFirewallDriver',
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::neutron

    class { '::neutron::agents::ml2::linuxbridge':
        physical_interface_mappings => $provider_interface_mappings,
        firewall_driver             => $firewall_driver,
    }

}
