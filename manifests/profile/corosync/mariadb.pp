# Setup MariaDB Resource
class easystack::profile::corosync::mariadb {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::mariadb

    # Setup MariaDB corosync service
    # TODO: Replace by ocf:heartbeat:mysql?
    cs_primitive { 'mariadb':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'mariadb',
        require         => Class['easystack::profile::mariadb'],
        operations      => {
            'monitor' => {
                'interval' => '10s',
            }
        },
    }

    cs_clone { 'mariadb-clone':
        ensure     => present,
        primitive  => 'mariadb',
        require    => Cs_primitive['mariadb'],
        interleave => true,
    }

}
