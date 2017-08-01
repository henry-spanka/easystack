# Setup Nova Consoleauth Resource
class easystack::profile::corosync::nova_consoleauth {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    cs_primitive { 'openstack-nova-consoleauth':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'openstack-nova-consoleauth',
        require         => Class['easystack::profile::nova::consoleauth'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'openstack-nova-consoleauth-clone':
        ensure     => present,
        primitive  => 'openstack-nova-consoleauth',
        require    => Cs_primitive['openstack-nova-consoleauth'],
        interleave => true,
    }

}
