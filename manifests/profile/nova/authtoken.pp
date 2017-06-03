# Setup Nova Keystone Authtoken
class easystack::profile::nova::authtoken (
    Array $controller_nodes = $::easystack::config::controller_nodes,
    String $vip             = $::easystack::config::controller_vip,
    String $nova_password   = $::easystack::config::keystone_nova_password,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    class { '::nova::keystone::authtoken':
        project_name        => 'services',
        project_domain_name => 'default',
        user_domain_name    => 'default',
        memcached_servers   => $controller_nodes_ip,
        username            => 'nova',
        password            => $nova_password,
        auth_url            => "http://${vip}:35357",
        auth_uri            => "http://${vip}:5000",
    }
}
