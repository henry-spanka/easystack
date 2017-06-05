# Setup Glance File Backend
class easystack::profile::glance::backend::file {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::glance

    class { 'glance::backend::file': }

}
