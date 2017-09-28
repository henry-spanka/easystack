# Define Memcached Relationships when managed through pacemaker
class easystack::profile::corosync::deps::memcached {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::memcached

    exec { 'wait-for-memcached-running':
        command   => 'systemctl is-active memcached.service | grep active',
        unless    => 'systemctl is-active memcached.service | grep active',
        tries     => '3',
        try_sleep => '10',
        path      => '/bin:/usr/bin',
        require   => Class['::easystack::profile::memcached'],
    }

    Class['::easystack::profile::memcached'] -> Exec['reauthenticate-across-all-nodes']
    Exec['reauthenticate-across-all-nodes'] -> Exec['wait-for-memcached-running']

}
