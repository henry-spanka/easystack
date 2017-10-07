# Setup Neutron API HAProxy Resource
class easystack::profile::haproxy::neutron_api (
    String $public_vip      = $::easystack::config::public_vip,
    Array $controller_nodes = $::easystack::config::controller_nodes,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::haproxy

    haproxy::listen { 'neutron_api_cluster':
        ipaddress => $public_vip,
        ports     => '9696',
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

    haproxy::balancermember { 'neutron_api_members':
        listening_service => 'neutron_api_cluster',
        ports             => '9696',
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
