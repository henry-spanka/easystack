# Setup Nova ConsoleAuth
class easystack::profile::nova::consoleauth {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    class { 'nova::consoleauth':
        manage_service => false,
        enabled        => false,
    }

}
