# Setup Neutron L3 Agent
class easystack::profile::neutron::agents::l3 {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::neutron

    class { '::neutron::agents::l3':
        interface_driver => 'linuxbridge',
    }

}
