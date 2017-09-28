# Setup Nova Placement Keystone Endpoint
class easystack::profile::nova::auth_placement (
    String $vip                = $::easystack::config::controller_vip,
    String $placement_password = $::easystack::config::keystone_nova_placement_password,
    String $region             = $::easystack::config::keystone_region,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    class { '::nova::keystone::auth_placement':
        password            => $placement_password,
        auth_name           => 'placement',
        configure_endpoint  => true,
        configure_user      => true,
        configure_user_role => true,
        service_name        => 'placement',
        public_url          => "http://${vip}:8778/placement",
        internal_url        => "http://${vip}:8778/placement",
        admin_url           => "http://${vip}:8778/placement",
        region              => $region,
        tenant              => 'services',
    }

    contain ::nova::keystone::auth_placement
}
