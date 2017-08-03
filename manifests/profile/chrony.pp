# Setup Chrony Service
class easystack::profile::chrony (
    Boolean $pool_use      = false,
    Array $servers         = [
        '0.pool.ntp.org',
        '1.pool.ntp.org',
        '2.pool.ntp.org',
        '3.pool.ntp.org',
    ],
    Boolean $service_manage = false,
) {
    # make sure the parameters are initialized
    include ::easystack

    class { 'chrony':
        pool_use       => $pool_use,
        servers        => $servers,
        service_manage => true,
        service_enable => $service_manage,
    }

    contain chrony

    # We need to override ensure
    if (!$service_manage) {
        Service <| title == 'chrony' |> {
            ensure => undef,
        }
    }

}
