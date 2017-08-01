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
        # We currently can not set service_manage to false and also disable the service.
        # That's why we need to override the ensure parameter using a Resource Collector afterwards
        service_ensure   => 'stopped',
    }

    Service <| title == 'haproxy' |> {
        ensure => undef,
    }

    sysctl::value { 'net.ipv4.ip_nonlocal_bind':
        value  => '1',
        before => Class['haproxy'],
    }

}
