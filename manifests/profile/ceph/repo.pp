# Setup Ceph Repo
class easystack::profile::ceph::repo {
    # make sure the parameters are initialized
    include ::easystack

    include ceph::repo

}
