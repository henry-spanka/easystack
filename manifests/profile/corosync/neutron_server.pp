# Setup Neutron Server Resource
class easystack::profile::corosync::neutron_server {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    cs_primitive { 'neutron-server':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'neutron-server',
        require         => Class['easystack::profile::neutron::server'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'neutron-server-clone':
        ensure     => present,
        primitive  => 'neutron-server',
        require    => Cs_primitive['neutron-server'],
        interleave => true,
    }

}
