# Setup Nova VNCProxy Resource
class easystack::profile::corosync::nova_vncproxy {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    cs_primitive { 'openstack-nova-novncproxy':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'openstack-nova-novncproxy',
        require         => Class['easystack::profile::nova::vncproxy'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'openstack-nova-novncproxy-clone':
        ensure     => present,
        primitive  => 'openstack-nova-novncproxy',
        require    => Cs_primitive['openstack-nova-novncproxy'],
        interleave => true,
    }

}
