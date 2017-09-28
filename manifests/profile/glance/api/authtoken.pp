# Setup Glance API Keystone Authtoken
class easystack::profile::glance::api::authtoken (
    Array $controller_nodes = $::easystack::config::controller_nodes,
    String $vip             = $::easystack::config::controller_vip,
    String $glance_password = $::easystack::config::keystone_glance_password,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::glance

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    class { '::glance::api::authtoken':
        project_name        => 'services',
        project_domain_name => 'default',
        user_domain_name    => 'default',
        memcached_servers   => $controller_nodes_ip,
        username            => 'glance',
        password            => $glance_password,
        notify              => Service['glance-api'],
        auth_url            => "http://${vip}:35357",
        auth_uri            => "http://${vip}:5000",
    }

    contain ::glance::api::authtoken
}
