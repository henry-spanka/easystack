# Setup Galera HAProxy Resource
class easystack::profile::haproxy::galera (
    String $vip             = $::easystack::config::controller_vip,
    Array $controller_nodes = $::easystack::config::controller_nodes,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::haproxy

    haproxy::listen { 'galera_cluster':
        ipaddress => $vip,
        ports     => '3306',
        mode      => 'tcp',
        options   => {
            'option'  => [
                'mysql-check',
                'tcpka',
            ],
            'balance' => 'source',
        },
    }

    $controller_master = $::easystack::config::controller_nodes.filter |Hash $params| {
        $params[master] == true
    }

    if ($controller_master == undef or length($controller_master) != 1) {
        fail('No controller master could be found')
    }

    $controller_master_fqdn = $controller_master.map |Hash $params| {
        $params[fqdn]
    }

    $controller_master_ip = $controller_master.map |Hash $params| {
        $params[ip]
    }

    $controller_nodes_slaves = $::easystack::config::controller_nodes.filter |Hash $params| {
        $params[master] == false
    }

    $controller_nodes_slaves_fqdn = $controller_nodes_slaves.map |Hash $params| {
        $params[fqdn]
    }

    $controller_nodes_slaves_ip = $controller_nodes_slaves.map |Hash $params| {
        $params[ip]
    }

    haproxy::balancermember { 'galera_members_master':
        listening_service => 'galera_cluster',
        ports             => '3306',
        server_names      => $controller_master_fqdn,
        ipaddresses       => $controller_master_ip,
        options           => [
            'check',
            'port 9200',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

    haproxy::balancermember { 'galera_members_slaves':
        listening_service => 'galera_cluster',
        ports             => '3306',
        server_names      => $controller_nodes_slaves_fqdn,
        ipaddresses       => $controller_nodes_slaves_ip,
        options           => [
            'backup',
            'check',
            'port 9200',
            'inter 2000',
            'rise 2',
            'fall 5',
        ],
    }

}
