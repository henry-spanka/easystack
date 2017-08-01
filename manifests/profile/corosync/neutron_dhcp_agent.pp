# Setup Neutron DHCP Agent Resource
class easystack::profile::corosync::neutron_dhcp_agent {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    cs_primitive { 'neutron-dhcp-agent':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'neutron-dhcp-agent',
        require         => Class['easystack::profile::neutron::agents::dhcp'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'neutron-dhcp-agent-clone':
        ensure     => present,
        primitive  => 'neutron-dhcp-agent',
        require    => Cs_primitive['neutron-dhcp-agent'],
        interleave => true,
    }

}
