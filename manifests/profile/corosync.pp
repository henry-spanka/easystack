# Setup Corosync Service
class easystack::profile::corosync (
    String $listen_ip       = ip_for_network($::easystack::config::management_network),
    Array $controller_nodes = $::easystack::config::controller_nodes,
    Boolean $stonith        = !($::is_virtual),
    Boolean $master         = false,
) {
    # make sure the parameters are initialized
    include ::easystack

    $controller_nodes_fqdn = $controller_nodes.map |Hash $params| {
        $params[fqdn]
    }

    class { 'corosync':
        authkey             => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
        bind_address        => $listen_ip,
        cluster_name        => 'openstack_corosync_cluster',
        enable_secauth      => true,
        set_votequorum      => true,
        quorum_members      => $controller_nodes_fqdn,
        manage_pcsd_service => true,
        rrp_mode            => 'active',
    }

    corosync::service { 'pacemaker':
        version => 1,
    }

    $user_hacluster_password = $::easystack::config::user_hacluster_password

    user { 'hacluster':
        password => pw_hash($user_hacluster_password, 'SHA-512', fqdn_rand_string(10)),
        groups   => 'haclient',
        require  => Class['corosync'],
    }

    if ($master) {
        $controller_nodes_fqdn_spaced = join($controller_nodes_fqdn, ' ')

        exec { 'reauthenticate-across-all-nodes':
            command     => "/usr/sbin/pcs cluster auth ${controller_nodes_fqdn_spaced} -u hacluster -p ${user_hacluster_password} --force",
            refreshonly => true,
            timeout     => '3600',
            tries       => '360',
            try_sleep   => '10',
            require     => Exec['wait-for-quorum'],
            subscribe   => User['hacluster'],
        }

        cs_property { 'pe-warn-series-max':
            value => 1000,
            tag   => 'corosync-property',
        }

        cs_property { 'pe-input-series-max':
            value => 1000,
            tag   => 'corosync-property',
        }

        cs_property { 'pe-error-series-max':
            value => 1000,
            tag   => 'corosync-property',
        }

        cs_property { 'cluster-recheck-interval':
            value => '5min',
            tag   => 'corosync-property',
        }

        if ($stonith) {
            # lint:ignore:quoted_booleans
            cs_property { 'stonith-enabled':
                value => 'true',
                tag   => 'corosync-property',
            }
            # lint:endignore
        } else {
            # lint:ignore:quoted_booleans
            cs_property { 'stonith-enabled':
                value => 'false',
                tag   => 'corosync-property',
            }
            # lint:endignore
        }
    }

    include ::firewalld

    firewalld_service { 'Allow Corosync and pacemaker multicast':
        ensure  => present,
        service => 'high-availability',
        zone    => 'public',
        before  => Class['corosync'],
    }

}
