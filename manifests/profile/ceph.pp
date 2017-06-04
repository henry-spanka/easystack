# Setup Ceph
class easystack::profile::ceph (
    String $fsid            = $::easystack::config::ceph_fsid,
    Array $monitors         = $::easystack::config::ceph_monitors,
    String $cluster_network = $::easystack::config::ceph_cluster_network,
    String $public_network  = $::easystack::config::ceph_public_network,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::ceph::repo

    $monitors_ip = $monitors.map |Hash $params| {
        $params[ip]
    }

    $monitors_ip_list = join($monitors_ip, ',')

    $monitors_hostname = $monitors.map |Hash $params| {
        split($params[fqdn], '\.')[0]
    }

    $monitors_hostname_list = join($monitors_hostname, ',')

    class { 'ceph':
        fsid                => $fsid,
        mon_initial_members => $monitors_hostname_list,
        mon_host            => $monitors_ip_list,
        cluster_network     => $cluster_network,
        public_network      => $public_network,
    }

}
