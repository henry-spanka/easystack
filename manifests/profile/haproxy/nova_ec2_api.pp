# Setup Nova EC2 API HAProxy Resource
class easystack::profile::haproxy::nova_ec2_api (
    String $vip             = $::easystack::config::controller_vip,
    Array $controller_nodes = $::easystack::config::controller_nodes,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::haproxy

    haproxy::listen { 'nova_ec2_api_cluster':
        ipaddress => $::easystack::config::controller_vip,
        ports     => '8773',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'tcpka',
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

    haproxy::balancermember { 'nova_ec2_api_members':
        listening_service => 'nova_ec2_api_cluster',
        ports             => '8773',
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
