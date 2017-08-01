# Setup Nova Scheduler Resource
class easystack::profile::corosync::nova_scheduler {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    cs_primitive { 'openstack-nova-scheduler':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'openstack-nova-scheduler',
        require         => Class['easystack::profile::nova::scheduler'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'openstack-nova-scheduler-clone':
        ensure     => present,
        primitive  => 'openstack-nova-scheduler',
        require    => Cs_primitive['openstack-nova-scheduler'],
        interleave => true,
    }

}
