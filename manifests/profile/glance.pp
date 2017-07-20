# Setup Glance Service
class easystack::profile::glance {
    # make sure the parameters are initialized
    include ::easystack

    include ::firewalld

    include ::glance

}
