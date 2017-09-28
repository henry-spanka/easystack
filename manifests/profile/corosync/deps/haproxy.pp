# Define HAProxy Relationships when managed through pacemaker
class easystack::profile::corosync::deps::haproxy {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::haproxy

    exec { 'wait-for-haproxy-running':
        command   => 'systemctl is-active haproxy.service | grep active',
        unless    => 'systemctl is-active haproxy.service | grep active',
        tries     => '3',
        try_sleep => '10',
        path      => '/bin:/usr/bin',
        require   => Class['easystack::profile::haproxy'],
    }

    Class['easystack::profile::haproxy'] -> Exec['reauthenticate-across-all-nodes']
    Exec['reauthenticate-across-all-nodes'] -> Exec['wait-for-haproxy-running']

}
