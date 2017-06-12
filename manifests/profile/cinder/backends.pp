# Setup Cinder Backends
class easystack::profile::cinder::backends (
    Array $enabled_backends = ['ceph'],
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::cinder

    class { 'cinder::backends':
        enabled_backends => $enabled_backends,
    }

}
