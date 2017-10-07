# Setup Nova Keystone Authtoken
class easystack::profile::nova::authtoken (
    Array $controller_nodes = $::easystack::config::controller_nodes,
    String $public_endpoint = $::easystack::config::public_endpoint,
    String $admin_endpoint  = $::easystack::config::admin_endpoint,
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
        auth_url            => "http://${admin_endpoint}:35357",
        auth_uri            => "http://${public_endpoint}:5000",
    }

    contain ::nova::keystone::authtoken
}
