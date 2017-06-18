# Setup Nova Neutron Network
class easystack::profile::nova::neutron (
    String $vip              = $::easystack::config::controller_vip,
    String $neutron_password = $::easystack::config::keystone_neutron_password,
    String $region           = $::easystack::config::keystone_region,
    String $shared_secret    = $::easystack::config::neutron_metadata_shared_secret,
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

    # lint:ignore:duplicate_params
    nova_config {
        'neutron/service_metadata_proxy': value => true;
        'neutron/metadata_proxy_shared_secret': value => $shared_secret;
    }
    # lint:endignore

}
