# Setup Neutron Metadata Agent Resource
class easystack::profile::corosync::neutron_metadata_agent {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    cs_primitive { 'neutron-metadata-agent':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'neutron-metadata-agent',
        require         => Class['easystack::profile::neutron::agents::metadata'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'neutron-metadata-agent-clone':
        ensure     => present,
        primitive  => 'neutron-metadata-agent',
        require    => Cs_primitive['neutron-metadata-agent'],
        interleave => true,
    }

}
