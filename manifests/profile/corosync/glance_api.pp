# Setup Glance API Resource
class easystack::profile::corosync::glance_api {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    # Setup glance corosync service
    cs_primitive { 'openstack-glance-api':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'openstack-glance-api',
        require         => Class['easystack::profile::glance::api'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'openstack-glance-api-clone':
        ensure     => present,
        primitive  => 'openstack-glance-api',
        require    => Cs_primitive['openstack-glance-api'],
        interleave => true,
    }

}
