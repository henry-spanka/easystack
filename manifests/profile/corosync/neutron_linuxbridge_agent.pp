# Setup Neutron Linuxbridge Agent Resource
class easystack::profile::corosync::neutron_linuxbridge_agent {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    cs_primitive { 'neutron-linuxbridge-agent':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'neutron-linuxbridge-agent',
        require         => Class['easystack::profile::neutron::agents::ml2::linuxbridge'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'neutron-linuxbridge-agent-clone':
        ensure     => present,
        primitive  => 'neutron-linuxbridge-agent',
        require    => Cs_primitive['neutron-linuxbridge-agent'],
        interleave => true,
    }

}
