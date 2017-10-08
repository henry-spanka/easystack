# Setup Horizon HAProxy Resource
class easystack::profile::haproxy::horizon (
    String $public_vip      = $::easystack::config::public_vip,
    Array $controller_nodes = $::easystack::config::controller_nodes,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::haproxy

    haproxy::listen { 'horizon_cluster':
        bind    => {
            "${public_vip}:80"  => [],
            "${public_vip}:443" => ['ssl', 'crt', '/etc/pki/tls/private/public_endpoint.pem'],
        },
        mode    => 'http',
        options => {
            'option'       => [
                'httpchk',
                'httplog',
                'forwardfor',
            ],
            'balance'      => 'source',
            'http-request' => [
                'set-header X-Forwarded-Port %[dst_port]',
                'add-header X-Forwarded-Proto https if { ssl_fc }'
            ],
            'redirect'     => 'scheme https if !{ ssl_fc }',
        },
    }

    $controller_nodes_fqdn = $controller_nodes.map |Hash $params| {
        $params[fqdn]
    }

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    haproxy::balancermember { 'horizon_members':
        listening_service => 'horizon_cluster',
        ports             => '80',
        server_names      => $controller_nodes_fqdn,
        ipaddresses       => $controller_nodes_ip,
        options           => [
            'check',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

}
