# Setup Ceph Block Storage Compute Client
class easystack::profile::ceph::compute_client (
    String $cinder_key            = $::easystack::config::ceph_cinder_key,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::firewalld

    file { '/var/run/ceph/guests':
        ensure  => 'directory',
        owner   => 'qemu',
        group   => 'libvirt',
        require => Class['easystack::profile::ceph'],
    }

    file { '/var/log/qemu':
        ensure  => 'directory',
        owner   => 'qemu',
        group   => 'libvirt',
        require => Class['easystack::profile::ceph'],
    }

    class { 'easystack::profile::ceph':
        mon         => false,
        osd         => false,
        keys        => {
            'client.cinder' => {
                'key'  => $cinder_key,
                'path' => '/etc/ceph/ceph.client.cinder.keyring',
            },
        },
        client_conf => {
            'rbd cache'                          => true,
            'rbd cache writethrough until flush' => true,
            'rbd cache size'                     => '134217700',
            'rbd cache max dirty'                => '100663275',
            'rbd cache target dirty'             => '33554430',
            'admin socket'                       => '/var/run/ceph/guests/$cluster-$type.$id.$pid.$cctid.asok',
            'log file'                           => '/var/log/qemu/qemu-guest-$pid.log',
            'rbd concurrent management ops'      => 20,
            'rbd default stripe_count'           => '16',
            'rbd default stripe_unit'            => '65536',
        },
    }
}
