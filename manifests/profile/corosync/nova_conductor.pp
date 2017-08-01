# Setup Nova Conductor Resource
class easystack::profile::corosync::nova_conductor {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    cs_primitive { 'openstack-nova-conductor':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'openstack-nova-conductor',
        require         => Class['easystack::profile::nova::conductor'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'openstack-nova-conductor-clone':
        ensure     => present,
        primitive  => 'openstack-nova-conductor',
        require    => Cs_primitive['openstack-nova-conductor'],
        interleave => true,
    }

}
