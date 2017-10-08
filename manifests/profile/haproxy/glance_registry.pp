# Setup Glance Registry HAProxy Resource
class easystack::profile::haproxy::glance_registry (
    String $vip             = $::easystack::config::controller_vip,
    Array $controller_nodes = $::easystack::config::controller_nodes,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::haproxy

    haproxy::listen { 'glance_registry_cluster':
        bind    => {
            "${vip}:9191" => ['ssl', 'crt', '/etc/pki/tls/private/admin_endpoint.pem'],
        },
        mode    => 'http',
        options => {
            'option'        => [
                'httpchk',
                'httplog',
                'forwardfor',
            ],
            'balance'       => 'source',
            'http-request'  => [
                'set-header X-Forwarded-Port %[dst_port]',
                'add-header X-Forwarded-Proto https if { ssl_fc }',
            ],
            'http-response' => [
                'set-header Server haproxy',
            ],
            'http-check'    => [
                'expect rstatus ((2|3)[0-9][0-9]|401)',
            ],
        },
    }

    $controller_nodes_fqdn = $controller_nodes.map |Hash $params| {
        $params[fqdn]
    }

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    haproxy::balancermember { 'glance_registry_members':
        listening_service => 'glance_registry_cluster',
        ports             => '9191',
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
