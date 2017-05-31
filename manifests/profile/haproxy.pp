# Setup Haproxy Service
class easystack::profile::haproxy {
    # make sure the parameters are initialized
    include ::easystack

    class { 'haproxy':
        global_options   => {
            chroot  => '/var/lib/haproxy',
            daemon  => '',
            user    => 'haproxy',
            group   => 'haproxy',
            pidfile => '/var/run/haproxy.pid',
            maxconn => '4000',
        },
        defaults_options => {
            'log'     => 'global',
            'stats'   => 'enable',
            'option'  => [
                'redispatch',
            ],
            'retries' => '3',
            'timeout' => [
                'http-request 10s',
                'queue 1m',
                'connect 10s',
                'client 1m',
                'server 1m',
                'check 10s',
            ],
            'maxconn' => '4000',
        },
    }

    sysctl::value { 'net.ipv4.ip_nonlocal_bind':
        value  => '1',
        before => Class['haproxy'],
    }

}
