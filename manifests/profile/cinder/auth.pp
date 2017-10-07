# Setup Cinder Keystone Endpoint
class easystack::profile::cinder::auth (
    String $public_endpoint = $::easystack::config::public_endpoint,
    String $cinder_password = $::easystack::config::keystone_cinder_password,
    String $region          = $::easystack::config::keystone_region,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::cinder

    class { '::cinder::keystone::auth':
        password              => $cinder_password,
        auth_name             => 'cinder',
        configure_endpoint    => false,
        configure_endpoint_v2 => true,
        configure_endpoint_v3 => true,
        configure_user        => true,
        configure_user_role   => true,
        service_name          => 'cinder',
        public_url            => "http://${public_endpoint}:8776/v1/%(tenant_id)s",
        internal_url          => "http://${public_endpoint}:8776/v1/%(tenant_id)s",
        admin_url             => "http://${public_endpoint}:8776/v1/%(tenant_id)s",
        public_url_v2         => "http://${public_endpoint}:8776/v2/%(tenant_id)s",
        internal_url_v2       => "http://${public_endpoint}:8776/v2/%(tenant_id)s",
        admin_url_v2          => "http://${public_endpoint}:8776/v2/%(tenant_id)s",
        public_url_v3         => "http://${public_endpoint}:8776/v3/%(tenant_id)s",
        internal_url_v3       => "http://${public_endpoint}:8776/v3/%(tenant_id)s",
        admin_url_v3          => "http://${public_endpoint}:8776/v3/%(tenant_id)s",
        region                => $region,
        tenant                => 'services',
    }
}
