# Setup Stats Haproxy Resource
class easystack::profile::haproxy::stats (
    String $local_ip               = ip_for_network($::easystack::config::management_network),
    String $haproxy_stats_password = $::easystack::config::haproxy_stats_password,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::haproxy

    haproxy::listen { 'haproxy_stats':
        ipaddress => $local_ip,
        ports     => '9000',
        mode      => 'http',
        options   => {
            'stats'        => [
                'enable',
                'uri /',
                "auth admin:${haproxy_stats_password}",
            ],
        },
    }

    firewalld_port { 'Allow haproxy stats for admin on port 9000 tcp - zone=admin':
        ensure   => present,
        zone     => 'admin',
        port     => 9000,
        protocol => 'tcp',
        tag      => 'haproxy-firewall',
    }

}
