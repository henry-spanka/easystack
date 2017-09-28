# Setup Cinder Scheduler Resource
class easystack::profile::corosync::cinder_scheduler {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::corosync::deps::cinder

    cs_primitive { 'openstack-cinder-scheduler':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'openstack-cinder-scheduler',
        require         => Class['easystack::profile::cinder::scheduler'],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            }
        },
    }

    cs_clone { 'openstack-cinder-scheduler-clone':
        ensure     => present,
        primitive  => 'openstack-cinder-scheduler',
        require    => Cs_primitive['openstack-cinder-scheduler'],
        interleave => true,
    }

}
