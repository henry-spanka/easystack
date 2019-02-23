# Setup Nova RBD Storage
class easystack::profile::nova::compute::rbd (
    String $cinder_key  = $::easystack::config::ceph_cinder_key,
    String $secret_uuid = $::easystack::config::ceph_cinder_secret_uuid,
    String $rbd_pool    = $::easystack::config::nova_rbd_pool
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    require ::easystack::profile::ceph::compute_client

    if ($rbd_pool) {
        $rbd_pool_real = $rbd_pool
    } else {
        $rbd_pool_real = $::easystack::params::nova_rbd_pool
    }

    class { '::nova::compute::rbd':
        libvirt_images_rbd_pool      => $rbd_pool_real,
        libvirt_images_rbd_ceph_conf => '/etc/ceph/ceph.conf',
        libvirt_rbd_user             => 'cinder',
        libvirt_rbd_secret_uuid      => $secret_uuid,
        libvirt_rbd_secret_key       => $cinder_key,
        rbd_keyring                  => 'client.cinder',
        manage_ceph_client           => false,
        require                      => Ceph::Keyring['client.cinder'],
    }
}
