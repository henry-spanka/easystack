# Setup Nova Keystone Endpoint
class easystack::profile::nova::auth (
    String $public_endpoint = $::easystack::config::public_endpoint,
    String $nova_password   = $::easystack::config::keystone_neutron_password,
    String $region          = $::easystack::config::keystone_region,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    class { '::nova::keystone::auth':
        password            => $nova_password,
        auth_name           => 'nova',
        configure_endpoint  => true,
        configure_user      => true,
        configure_user_role => true,
        service_name        => 'nova',
        public_url          => "https://${public_endpoint}:8774/v2.1",
        internal_url        => "https://${public_endpoint}:8774/v2.1",
        admin_url           => "https://${public_endpoint}:8774/v2.1",
        region              => $region,
        tenant              => 'services',
    }

    contain ::nova::keystone::auth
}
