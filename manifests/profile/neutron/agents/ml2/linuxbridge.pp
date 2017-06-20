# Setup Neutron Linuxbridge ML2 Agent
class easystack::profile::neutron::agents::ml2::linuxbridge (
    String $local_ip                   = ip_for_network($::easystack::config::neutron_network),
    Array $provider_interface_mappings = ['provider:eth2'],
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::neutron

    class { '::neutron::agents::ml2::linuxbridge':
        physical_interface_mappings => $provider_interface_mappings,
        local_ip                    => $local_ip,
        l2_population               => true,
        tunnel_types                => ['vxlan'],
    }

}
