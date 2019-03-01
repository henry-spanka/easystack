# Setup Ceph Monitor
class easystack::profile::ceph::monitor (
    String $admin_key         = $::easystack::config::ceph_admin_key,
    String $bootstrap_osd_key = $::easystack::config::ceph_bootstrap_osd_key,
    String $bootstrap_mgr_key = $::easystack::config::ceph_bootstrap_mgr_key,
    String $glance_key            = $::easystack::config::ceph_glance_key,
    String $cinder_key            = $::easystack::config::ceph_cinder_key,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::firewalld

    firewalld_port { 'Allow ceph monitor on port 6789 tcp':
        ensure   => present,
        zone     => 'ceph_public',
        port     => 6789,
        protocol => 'tcp',
        tag      => 'ceph-firewall',
    }

    firewalld_port { 'Allow ceph manager from port 6800 to 7300 tcp on zone=ceph_public':
        ensure   => present,
        zone     => 'ceph_public',
        port     => '6800-7300',
        protocol => 'tcp',
        tag      => 'ceph-firewall',
    }

    firewalld_port { 'Allow ceph dashboard on port 7000/tcp on zone=admin':
        ensure   => present,
        zone     => 'admin',
        port     => '7000',
        protocol => 'tcp',
        tag      => 'ceph-firewall',
    }

    class { 'easystack::profile::ceph':
        mon  => true,
        osd  => false,
        keys => {
            'client.admin'         => {
                'key'  => $admin_key,
                'caps' => {
                    'mon' => 'allow *',
                    'osd' => 'allow *',
                    'mds' => 'allow',
                    'mgr' => 'allow *',
                },
                'path' => '/etc/ceph/ceph.client.admin.keyring',
            },
            'client.bootstrap-mgr' => {
                'key'  => $bootstrap_mgr_key,
                'caps' => {
                    'mon'  => 'allow profile bootstrap-mgr',
                },
                'path' => '/var/lib/ceph/bootstrap-mgr/ceph.keyring',
            },
            'client.bootstrap-osd' => {
                'key'  => $bootstrap_osd_key,
                'caps' => {
                    'mon' => 'allow profile bootstrap-osd',
                },
                'path' => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
            },
            'client.glance'        => {
                'key'  => $glance_key,
                'caps' => {
                    'mon' => 'profile rbd',
                    'osd' => 'profile rbd pool=images',
                },
                'path' => '/etc/ceph/ceph.client.glance.keyring',
            },
            'client.cinder'        => {
                'key'  => $cinder_key,
                'caps' => {
                    'mon' => 'profile rbd',
                    'osd' => 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd pool=images, profile rbd pool=cache_storage, profile rbd pool=vms_ssd',
                },
                'path' => '/etc/ceph/ceph.client.cinder.keyring',
            }
        }
    }

}
