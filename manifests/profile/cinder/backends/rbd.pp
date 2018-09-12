# Setup Cinder rbd_secret_uuid Backend
class easystack::profile::cinder::backends::rbd (
    String $secret_uuid = $::easystack::config::ceph_cinder_secret_uuid,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::cinder

    require ::easystack::profile::ceph::controller_client

    cinder::backend::rbd { 'rbd_volumes':
        rbd_pool             => 'volumes',
        rbd_user             => 'cinder',
        rbd_ceph_conf        => '/etc/ceph/ceph.conf',
        rbd_secret_uuid      => $secret_uuid,
        rbd_max_clone_depth  => '5',
        rbd_store_chunk_size => '8',
        require              => Ceph::Keyring['client.cinder'],
    }
}
