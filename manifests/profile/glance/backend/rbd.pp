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

    include patch

    # If we use RBD as backend we need to patch the rbd glance driver to allow
    # the creation of sparse images when an image is uploaded to glance
    # See: https://review.openstack.org/#/c/430641/
    patch::file { '/usr/lib/python2.7/site-packages/glance_store/_drivers/rbd.py':
        diff_source => 'puppet:///modules/easystack/glance_store/785fb07.diff',
        require     => Anchor['easystack::openstack::install_1::end'],
        notify      => Anchor['glance::service::begin'],
    }

}
