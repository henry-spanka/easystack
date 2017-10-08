# Setup Nova VNCProxy HAProxy Resource
class easystack::profile::haproxy::nova_vncproxy (
    String $public_vip      = $::easystack::config::public_vip,
    Array $controller_nodes = $::easystack::config::controller_nodes,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::haproxy

    haproxy::listen { 'nova_vncproxy_cluster':
        bind    => {
            "${public_vip}:6080" => ['ssl', 'crt', '/etc/pki/tls/private/public_endpoint.pem'],
        },
        mode    => 'http',
        options => {
            'option'       => [
                'httpchk GET /',
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

    haproxy::balancermember { 'nova_vncproxy_members':
        listening_service => 'nova_vncproxy_cluster',
        ports             => '6080',
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
