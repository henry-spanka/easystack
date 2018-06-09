# Setup Ceph Block Storage Controller Client
class easystack::profile::ceph::controller_client (
    String $glance_key            = $::easystack::config::ceph_glance_key,
    String $cinder_key            = $::easystack::config::ceph_cinder_key,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::firewalld

    class { 'easystack::profile::ceph':
        mon  => false,
        osd  => false,
        keys => {
            'client.glance' => {
                'key'  => $glance_key,
                'path' => '/etc/ceph/ceph.client.glance.keyring',
            },
            'client.cinder' => {
                'key'  => $cinder_key,
                'path' => '/etc/ceph/ceph.client.cinder.keyring',
            },
        },
    }
}
