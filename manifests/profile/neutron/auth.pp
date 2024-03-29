# Setup Neutron Keystone Endpoint
class easystack::profile::neutron::auth (
    String $public_endpoint  = $::easystack::config::public_endpoint,
    String $neutron_password = $::easystack::config::keystone_neutron_password,
    String $region           = $::easystack::config::keystone_region,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::neutron

    class { '::neutron::keystone::auth':
        password            => $neutron_password,
        auth_name           => 'neutron',
        configure_endpoint  => true,
        configure_user      => true,
        configure_user_role => true,
        service_name        => 'neutron',
        public_url          => "https://${public_endpoint}:9696",
        internal_url        => "https://${public_endpoint}:9696",
        admin_url           => "https://${public_endpoint}:9696",
        region              => $region,
        tenant              => 'services',
    }

    contain ::neutron::keystone::auth
}
