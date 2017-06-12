# Setup Cinder Keystone Authtoken
class easystack::profile::cinder::authtoken (
    Array $controller_nodes = $::easystack::config::controller_nodes,
    String $vip             = $::easystack::config::controller_vip,
    String $cinder_password = $::easystack::config::keystone_cinder_password,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::cinder

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    class { '::cinder::keystone::authtoken':
        project_name        => 'services',
        project_domain_name => 'default',
        user_domain_name    => 'default',
        memcached_servers   => $controller_nodes_ip,
        username            => 'cinder',
        password            => $cinder_password,
        notify              => Service['cinder-api'],
        auth_url            => "http://${vip}:35357",
        auth_uri            => "http://${vip}:5000",
    }
}
