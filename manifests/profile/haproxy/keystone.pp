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
        ipaddress => $vip,
        ports     => '35357',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
                'httpchk',
                'tcplog',
            ],
            'balance' => 'source',
        },
    }

    # keystone public internal
    haproxy::listen { 'keystone_public_internal_cluster':
        ipaddress => $public_vip,
        ports     => '5000',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
                'httpchk',
                'tcplog',
            ],
            'balance' => 'source',
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
