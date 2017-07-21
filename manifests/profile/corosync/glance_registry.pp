# Setup Glance Registry Resource
class easystack::profile::corosync::glance_registry {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    # Setup glance corosync service
    cs_primitive { 'openstack-glance-registry':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'openstack-glance-registry',
        require         => Service['glance-registry'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'openstack-glance-registry-clone':
        ensure     => present,
        primitive  => 'openstack-glance-registry',
        require    => Cs_primitive['openstack-glance-registry'],
        interleave => true,
    }

}
