# Setup Nova Neutron Network
class easystack::profile::nova::neutron (
    String $public_endpoint  = $::easystack::config::public_endpoint,
    String $admin_endpoint   = $::easystack::config::admin_endpoint,
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
        neutron_url                 => "https://${public_endpoint}:9696",
        neutron_auth_url            => "https://${admin_endpoint}:35357/v3",
        firewall_driver             => 'nova.virt.firewall.NoopFirewallDriver',
        neutron_region_name         => $region,
    }

}
