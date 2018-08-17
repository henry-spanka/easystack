# Setup Glance RBD Backend
class easystack::profile::glance::backend::rbd {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::glance

    require ::easystack::profile::ceph::controller_client

    class { 'glance::backend::rbd':
        rbd_store_user      => 'glance',
        rbd_store_pool      => 'images',
        rbd_store_ceph_conf => '/etc/ceph/ceph.conf',
        multi_store         => true,
        require             => Ceph::Keyring['client.glance'],
    }

}
