# Setup Keystone HAProxy Resource
class easystack::profile::haproxy::keystone (
    String $vip             = $::easystack::config::controller_vip,
    String $public_vip      = $::easystack::config::public_vip,
    Array $controller_nodes = $::easystack::config::controller_nodes,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::haproxy

    # Keystone admin
    haproxy::listen { 'keystone_admin_cluster':
        bind    => {
            "${vip}:35357" => ['ssl', 'crt', '/etc/pki/tls/private/admin_endpoint.pem'],
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
        },
    }

    # keystone public internal
    haproxy::listen { 'keystone_public_internal_cluster':
        bind    => {
            "${public_vip}:5000" => ['ssl', 'crt', '/etc/pki/tls/private/public_endpoint.pem'],
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
        },
    }

    $controller_nodes_fqdn = $controller_nodes.map |Hash $params| {
        $params[fqdn]
    }

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    haproxy::balancermember { 'keystone_admin_members':
        listening_service => 'keystone_admin_cluster',
        ports             => '35357',
        server_names      => $controller_nodes_fqdn,
        ipaddresses       => $controller_nodes_ip,
        options           => [
            'check',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    haproxy::balancermember { 'keystone_public_internal_members':
        listening_service => 'keystone_public_internal_cluster',
        ports             => '5000',
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
