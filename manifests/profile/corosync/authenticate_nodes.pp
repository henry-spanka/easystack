# Authenticate Corosync Nodes
class easystack::profile::corosync::authenticate_nodes (
    Array $controller_nodes         = $::easystack::config::controller_nodes,
    String $user_hacluster_password = $::easystack::config::user_hacluster_password,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::corosync

    $controller_nodes_fqdn = $controller_nodes.map |Hash $params| {
        $params[fqdn]
    }

    $controller_nodes_fqdn_spaced = join($controller_nodes_fqdn, ' ')

    exec { 'reauthenticate-across-all-nodes':
        command   => "/usr/sbin/pcs cluster auth ${controller_nodes_fqdn_spaced} -u hacluster -p ${user_hacluster_password} --force",
        unless    => 'test -f /root/pacemaker_authenticated',
        timeout   => '3600',
        tries     => '360',
        try_sleep => '10',
        provider  => shell,
        require   => [
            Service['pcsd'],
            User['hacluster'],
        ],
    }

    file { '/root/pacemaker_authenticated':
        ensure  => file,
        source  => 'puppet:///modules/easystack/pacemaker_authenticated',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Exec['reauthenticate-across-all-nodes'],
    }

    Anchor['easystack::corosync::authenticate::begin']
    -> Class['easystack::profile::corosync::authenticate_nodes']
    ~> Anchor['easystack::corosync::authenticate::end']

}
