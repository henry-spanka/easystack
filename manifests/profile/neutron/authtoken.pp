# Setup Neutron Keystone Authtoken
class easystack::profile::neutron::authtoken (
    Array $controller_nodes  = $::easystack::config::controller_nodes,
    String $public_endpoint  = $::easystack::config::public_endpoint,
    String $admin_endpoint   = $::easystack::config::admin_endpoint,
    String $neutron_password = $::easystack::config::keystone_neutron_password,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::neutron

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    class { '::neutron::keystone::authtoken':
        project_name        => 'services',
        project_domain_name => 'default',
        user_domain_name    => 'default',
        memcached_servers   => $controller_nodes_ip,
        username            => 'neutron',
        password            => $neutron_password,
        auth_uri            => "http://${public_endpoint}:5000",
        auth_url            => "http://${admin_endpoint}:35357",
    }

    contain ::neutron::keystone::authtoken

}
