# Setup Ceph Block Storage
class easystack::profile::ceph::storage (
    String $admin_key         = $::easystack::config::ceph_admin_key,
    String $bootstrap_osd_key = $::easystack::config::ceph_bootstrap_osd_key,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::firewalld

    firewalld_port { 'Allow ceph osds from port 6800 to 7300 tcp on zone=ceph_cluster':
        ensure   => present,
        zone     => 'ceph_cluster',
        port     => '6800-7300',
        protocol => 'tcp',
        tag      => 'ceph-firewall',
    }

    firewalld_port { 'Allow ceph osds from port 6800 to 7300 tcp on zone=ceph_public':
        ensure   => present,
        zone     => 'ceph_public',
        port     => '6800-7300',
        protocol => 'tcp',
        tag      => 'ceph-firewall',
    }

    class { 'easystack::profile::ceph':
        mon  => false,
        osd  => false,
        keys => {
            'client.bootstrap-osd' => {
                'key'  => $bootstrap_osd_key,
                'path' => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
            }
        }
    }
}
