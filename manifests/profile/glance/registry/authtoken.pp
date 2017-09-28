# Setup Glance Registry Keystone Authtoken
class easystack::profile::glance::registry::authtoken (
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

    class { '::glance::registry::authtoken':
        project_name        => 'services',
        project_domain_name => 'default',
        user_domain_name    => 'default',
        memcached_servers   => $controller_nodes_ip,
        username            => 'glance',
        password            => $glance_password,
        notify              => Service['glance-registry'],
    }

    contain ::glance::registry::authtoken
}
