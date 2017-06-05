# Setup Glance RBD Backend
class easystack::profile::glance::backend::rbd (
    String $glance_key = $::easystack::config::ceph_glance_key,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::glance

    include ::easystack::profile::ceph

    ceph::key { 'client.glance':
        secret => $glance_key,
        mode   => '0640',
        group  => 'glance',
        user   => 'root',
    }

    class { 'glance::backend::rbd':
        rbd_store_user      => 'glance',
        rbd_store_pool      => 'images',
        rbd_store_ceph_conf => '/etc/ceph/ceph.conf',
        multi_store         => true,
        require             => Ceph::Key['client.glance']
    }

}
