# Bootstrap the Galera Cluster
class easystack::profile::mariadb::galera_bootstrap (
    Array $controller_nodes = $::easystack::config::controller_nodes,
) {
    # make sure the parameters are initialized
    include ::easystack

    include easystack::profile::mariadb::galera

    $controller_nodes_fqdn = $controller_nodes.map |Hash $params| {
        $params[fqdn]
    }

    $controller_nodes_fqdn_spaced = join($controller_nodes_fqdn, ' ')

    exec { 'bootstrap_galera_cluster':
        command  => '/usr/bin/galera_new_cluster',
        unless   => "nmap -Pn -p 4567 ${controller_nodes_fqdn_spaced} | grep -q '4567/tcp open'",
        require  => Class['mysql::server::installdb'],
        before   => Service['mysqld'],
        provider => shell,
        path     => '/usr/bin:/bin:/usr/sbin:/sbin'
    }

}
