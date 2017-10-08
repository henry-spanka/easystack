# Setup Glance Registry Keystone Authtoken
class easystack::profile::glance::registry::authtoken (
    Array $controller_nodes = $::easystack::config::controller_nodes,
    String $vip             = $::easystack::config::controller_vip,
    String $glance_password = $::easystack::config::keystone_glance_password,
    String $public_endpoint = $::easystack::config::public_endpoint,
    String $admin_endpoint  = $::easystack::config::admin_endpoint,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::glance

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    class { '::glance::registry::authtoken':
        project_name        => 'services',
        project_domain_name => 'default',
        user_domain_name    => 'default',
        memcached_servers   => $controller_nodes_ip,
        username            => 'glance',
        password            => $glance_password,
        auth_url            => "https://${admin_endpoint}:35357",
        auth_uri            => "https://${public_endpoint}:5000",
        notify              => Service['glance-registry'],
    }

    contain ::glance::registry::authtoken
}
