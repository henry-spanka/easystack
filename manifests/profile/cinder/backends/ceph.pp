# Setup Cinder Ceph Backend
class easystack::profile::cinder::backends::ceph (
    String $cinder_key  = $::easystack::config::ceph_cinder_key,
    String $secret_uuid = $::easystack::config::ceph_cinder_secret_uuid,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::cinder

    include ::easystack::profile::ceph

    ceph::key { 'client.cinder':
        secret => $cinder_key,
        mode   => '0640',
        group  => 'cinder',
        user   => 'root',
    }

    cinder::backend::rbd { 'ceph':
        rbd_pool        => 'volumes',
        rbd_user        => 'cinder',
        rbd_ceph_conf   => '/etc/ceph/ceph.conf',
        rbd_secret_uuid => $secret_uuid,
        require         => Ceph::Key['client.cinder']
    }

}
