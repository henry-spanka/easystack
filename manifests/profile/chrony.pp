# Setup Chrony Service
class easystack::profile::chrony (
    Boolean $pool_use      = false,
    Array $servers         = [
        '0.pool.ntp.org',
        '1.pool.ntp.org',
        '2.pool.ntp.org',
        '3.pool.ntp.org',
    ],
) {
    # make sure the parameters are initialized
    include ::easystack

    class { 'chrony':
        pool_use       => $pool_use,
        servers        => $servers,
        service_manage => true,
        service_enable => true,
    }

    contain chrony

    Anchor['easystack::time::begin']
    -> Class['easystack::profile::chrony']
    ~> Anchor['easystack::time::end']

}
