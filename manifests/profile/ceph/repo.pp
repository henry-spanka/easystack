# Setup Ceph Repo
class easystack::profile::ceph::repo {
    # make sure the parameters are initialized
    include ::easystack

    class { 'ceph::repo':
        enable_sig  => true,
        enable_epel => false,
    }

}
