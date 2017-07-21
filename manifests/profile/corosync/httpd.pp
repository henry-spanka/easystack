# Setup Httpd Resource
class easystack::profile::corosync::httpd {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    # Setup httpd corosync service
    cs_primitive { 'httpd':
        ensure          => present,
        primitive_class => 'systemd',
        primitive_type  => 'httpd',
        require         => [
            Class['apache'],
            Exec['restart_keystone'],
        ],
        operations      => {
            'monitor' => {
                'interval' => '5s',
            },
            'start'   => {
                'timeout'  => '300s',
                'interval' => '0s',
            },
            'stop'    => {
                'timeout'  => '120s',
                'interval' => '0s',
            },
        },
    }

    cs_clone { 'httpd-clone':
        ensure     => present,
        primitive  => 'httpd',
        require    => Cs_primitive['httpd'],
        interleave => true,
    }

}
