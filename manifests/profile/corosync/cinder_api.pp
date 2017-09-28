# Setup Cinder API Resource
class easystack::profile::corosync::cinder_api {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::corosync::deps::cinder

    cs_primitive { 'openstack-cinder-api':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'openstack-cinder-api',
        require         => Class['easystack::profile::cinder::api'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'openstack-cinder-api-clone':
        ensure     => present,
        primitive  => 'openstack-cinder-api',
        require    => Cs_primitive['openstack-cinder-api'],
        interleave => true,
    }

}
