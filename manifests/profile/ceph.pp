# Setup Ceph
class easystack::profile::ceph (
    String $fsid                       = $::easystack::config::ceph_fsid,
    Array $monitors                    = $::easystack::config::ceph_monitors,
    String $cluster_network            = $::easystack::config::ceph_cluster_network,
    String $public_network             = $::easystack::config::ceph_public_network,
    Integer $osd_crush_chooseleaf_type = $::easystack::config::ceph_osd_crush_chooseleaf_type,
    String $mon_key                    = $::easystack::config::ceph_mon_key,
    Hash $keys                         = {},
    Hash $disks                        = {},
    Boolean $mon                       = false,
    Boolean $osd                       = false,
    Hash $client_conf                  = {},
) {
    # make sure the parameters are initialized
    include ::easystack

    $monitors_ip = $monitors.map |Hash $params| {
        $params[ip]
    }

    $monitors_ip_list = join($monitors_ip, ',')

    $monitors_hostname = $monitors.map |Hash $params| {
        split($params[fqdn], '\.')[0]
    }

    $monitors_hostname_list = join($monitors_hostname, ',')

    class { 'ceph':
        mon           => $mon,
        osd           => $osd,
        rgw           => false,
        mds           => false,
        manage_repo   => false,
        repo_version  => 'luminous',
        mon_id        => $::hostname,
        mon_key       => $mon_key,
        conf          => {
            'global' => {
                'fsid'                      => $fsid,
                'mon_initial_members'       => $monitors_hostname_list,
                'mon_host'                  => $monitors_ip_list,
                'public_network'            => $public_network,
                'cluster_network'           => $cluster_network,
                'auth_supported'            =>'cephx',
                'filestore_xattr_use_omap'  => true,
                'osd_crush_chooseleaf_type' => $osd_crush_chooseleaf_type,
            },
            'client' => $client_conf,
        },
        keys          => $keys,
        disks         => $disks,
        prerequisites => ['redhat-lsb-core', 'python2-setuptools.noarch'],
    }

    file { '/etc/yum.repos.d/ceph.repo':
        ensure => absent
    }

    package { 'centos-release-ceph-luminous':
        ensure => installed,
        require => File['/etc/yum.repos.d/ceph.repo'],
        before => Class['::ceph::install'],
    }

    contain ceph

    Anchor['easystack::ceph::install::begin']
    -> Class['easystack::profile::ceph']

    Class['easystack::profile::ceph']
    -> Anchor['easystack::ceph::install::end']

    Firewalld_port <|tag == 'ceph-firewall'|>
    -> Class['ceph']
}
