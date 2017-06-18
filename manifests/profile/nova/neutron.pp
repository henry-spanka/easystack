# Setup Nova Neutron Network
class easystack::profile::nova::neutron (
    String $vip              = $::easystack::config::controller_vip,
    String $neutron_password = $::easystack::config::keystone_neutron_password,
    String $region           = $::easystack::config::keystone_region,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    class { 'nova::network::neutron':
        neutron_project_name        => 'services',
        neutron_project_domain_name => 'default',
        neutron_user_domain_name    => 'default',
        neutron_username            => 'neutron',
        neutron_password            => $neutron_password,
        neutron_url                 => "http://${vip}:9696",
        neutron_auth_url            => "http://${vip}:35357/v3",
        firewall_driver             => 'nova.virt.firewall.NoopFirewallDriver',
        neutron_region_name         => $region,
    }

}
