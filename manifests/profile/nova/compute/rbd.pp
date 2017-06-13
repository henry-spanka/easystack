# Setup Nova RBD Storage
class easystack::profile::nova::compute::rbd (
    String $nova_key  = $::easystack::config::ceph_nova_key,
    String $secret_uuid = $::easystack::config::ceph_cinder_secret_uuid,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    include ::easystack::profile::ceph

    ceph::key { 'client.nova':
        secret => $nova_key,
        mode   => '0640',
        group  => 'nova',
        user   => 'root',
    }

    class { '::nova::compute::rbd':
        libvirt_images_rbd_pool      => 'vms',
        libvirt_images_rbd_ceph_conf => '/etc/ceph/ceph.conf',
        libvirt_rbd_user             => 'nova',
        libvirt_rbd_secret_uuid      => $secret_uuid,
        libvirt_rbd_secret_key       => $nova_key,
        manage_ceph_client           => false,
    }
}
