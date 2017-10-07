# Setup Keystone Endpoint
class easystack::profile::keystone::endpoint (
    String $public_endpoint = $::easystack::config::public_endpoint,
    String $admin_endpoint  = $::easystack::config::admin_endpoint,
    String $region          = $::easystack::config::keystone_region,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::keystone

    # Installs the service user endpoint.
    class { 'keystone::endpoint':
        public_url   => "http://${public_endpoint}:5000",
        admin_url    => "http://${admin_endpoint}:35357",
        internal_url => "http://${public_endpoint}:5000",
        region       => $region,
        #   If the version is set to the empty string (''), then it won't be
        #   used. This is the expected behaviour since Keystone V3 handles API versions
        #   from the context.
        version      => '',
    }

    contain keystone::endpoint

}
