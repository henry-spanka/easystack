# Setup Glance Keystone Endpoint
class easystack::profile::glance::auth (
    String $public_endpoint = $::easystack::config::public_endpoint,
    String $glance_password = $::easystack::config::keystone_glance_password,
    String $region          = $::easystack::config::keystone_region,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::glance

    class { '::glance::keystone::auth':
        password            => $glance_password,
        auth_name           => 'glance',
        configure_endpoint  => true,
        configure_user      => true,
        configure_user_role => true,
        service_name        => 'glance',
        public_url          => "https://${public_endpoint}:9292",
        internal_url        => "https://${public_endpoint}:9292",
        admin_url           => "https://${public_endpoint}:9292",
        region              => $region,
        tenant              => 'services',
    }

    contain ::glance::keystone::auth
}
