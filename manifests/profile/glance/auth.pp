# Setup Glance Keystone Endpoint
class easystack::profile::glance::auth (
    String $vip             = $::easystack::config::controller_vip,
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
        public_url          => "http://${vip}:9292",
        internal_url        => "http://${vip}:9292",
        admin_url           => "http://${vip}:9292",
        region              => $region,
        tenant              => 'services',
        require             => Class['::easystack::profile::keystone'],
    }
}
