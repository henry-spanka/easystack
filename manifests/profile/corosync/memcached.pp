# Setup Memcached Resource
class easystack::profile::corosync::memcached {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync
    include ::easystack::profile::memcached

    # Setup memcached service
    cs_primitive { 'memcached':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'memcached',
        require         => Class['easystack::profile::memcached'],
        operations      => {
            'monitor' => {
                'interval' => '30s',
            }
        },
    }

    cs_clone { 'memcached-clone':
        ensure     => present,
        primitive  => 'memcached',
        require    => Cs_primitive['memcached'],
        interleave => true,
    }

}
