# Setup Cinder API HAProxy Resource
class easystack::profile::haproxy::cinder_api (
    String $vip             = $::easystack::config::controller_vip,
    Array $controller_nodes = $::easystack::config::controller_nodes,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::haproxy

    haproxy::listen { 'cinder_api_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '8776',
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

    haproxy::balancermember { 'cinder_api_members':
        listening_service => 'cinder_api_cluster',
        ports             => '8776',
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
