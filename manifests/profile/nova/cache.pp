# Setup Nova Cell
class easystack::profile::nova::cache (
    Array $controller_nodes = $::easystack::config::controller_nodes,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    $controller_nodes_ip = $controller_nodes.map |Hash $params| {
        $params[ip]
    }

    class { '::nova::cache':
        enabled          => true,
        backend          => 'oslo_cache.memcache_pool',
        memcache_servers => $controller_nodes_ip,
    }

    contain ::nova::cache

}
