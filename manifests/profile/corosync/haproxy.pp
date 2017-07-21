# Setup HAProxy Resource
class easystack::profile::corosync::haproxy {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    include ::easystack::profile::corosync::vip

    # Setup Haproxy Corosync service and VIP
    cs_primitive { 'haproxy':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'haproxy',
        operations      => {
            'monitor' => {
                'interval' => '1s',
            }
        },
        require         => Class['haproxy'],
    }

    cs_clone { 'haproxy-clone':
        ensure    => present,
        primitive => 'haproxy',
        require   => Cs_primitive['haproxy'],
    }

    cs_order { 'vip_before_haproxy':
        first   => 'vip',
        second  => 'haproxy-clone',
        kind    => 'Optional',
        require => [
            Cs_clone['haproxy-clone'],
            Cs_primitive['vip'],
        ],
    }

    cs_colocation { 'vip_with_haproxy':
        primitives => ['haproxy-clone', 'vip'],
        require    => Cs_order['vip_before_haproxy'],
    }

}
