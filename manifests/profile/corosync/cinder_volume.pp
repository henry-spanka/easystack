# Setup Cinder Volume Resource
class easystack::profile::corosync::cinder_volume {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::corosync::deps::cinder

    cs_primitive { 'openstack-cinder-volume':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'openstack-cinder-volume',
        require         => Class['easystack::profile::cinder::volume'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'openstack-cinder-volume-clone':
        ensure     => present,
        primitive  => 'openstack-cinder-volume',
        require    => Cs_primitive['openstack-cinder-volume'],
        interleave => true,
    }

}
