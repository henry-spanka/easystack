# Setup Nova API Resource
class easystack::profile::corosync::nova_api {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    cs_primitive { 'openstack-nova-api':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'openstack-nova-api',
        require         => Class['easystack::profile::nova::api'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'openstack-nova-api-clone':
        ensure     => present,
        primitive  => 'openstack-nova-api',
        require    => Cs_primitive['openstack-nova-api'],
        interleave => true,
    }

}
