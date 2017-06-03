# Setup Ceph Block Storage
class easystack::profile::ceph::storage (
    String $bootstrap_osd_key = $::easystack::config::ceph_bootstrap_osd_key,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::ceph

    include ::firewalld

    firewalld_port { 'Allow ceph osds from port 6800 to 7300 tcp':
        ensure   => present,
        zone     => 'public',
        port     => '6800-7300',
        protocol => 'tcp',
        tag      => 'ceph-firewall',
    }

    ceph::key {'client.bootstrap-osd':
        keyring_path => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
        secret       => $bootstrap_osd_key,
    }

}
