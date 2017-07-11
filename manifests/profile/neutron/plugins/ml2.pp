# Setup Neutron Server
class easystack::profile::neutron::plugins::ml2 {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::neutron

    class { '::neutron::plugins::ml2':
        type_drivers          => ['flat', 'vlan'],
        tenant_network_types  => [],
        mechanism_drivers     => ['linuxbridge'],
        extension_drivers     => ['port_security'],
        flat_networks         => ['provider'],
        vni_ranges            => ['1:1000'],
        enable_security_group => true,
    }

    # lint:ignore:duplicate_params
    neutron_config {
        'securitygroup/enable_ipset': value => true;
    }
    # lint:endignore

}
