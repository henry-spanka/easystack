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

    contain haproxy

    sysctl::value { 'net.ipv4.ip_nonlocal_bind':
        value  => '1',
        before => Anchor['easystack::haproxy::service::begin'],
    }

    Anchor['easystack::haproxy::install::begin']
    -> Haproxy::Install['haproxy']
    -> Haproxy::Config['haproxy']
    ~> Anchor['easystack::haproxy::install::end']

    Anchor['easystack::haproxy::service::begin']
    -> Haproxy::Service['haproxy']
    ~> Anchor['easystack::haproxy::service::end']

}
