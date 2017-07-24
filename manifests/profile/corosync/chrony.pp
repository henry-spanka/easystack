# Setup Chrony Resource
class easystack::profile::corosync::chrony {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::chrony

    # Setup chrony service
    cs_primitive { 'chrony':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'chronyd',
        require         => Class['easystack::profile::chrony'],
        operations      => {
            'monitor' => {
                'interval' => '60s',
            }
        },
    }

    cs_clone { 'chrony-clone':
        ensure     => present,
        primitive  => 'chrony',
        require    => Cs_primitive['chrony'],
        interleave => true,
    }

}
