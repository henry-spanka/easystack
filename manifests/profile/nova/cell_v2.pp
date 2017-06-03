# Setup Nova Cell
class easystack::profile::nova::cell_v2 {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    include ::nova::cell_v2::simple_setup

}
