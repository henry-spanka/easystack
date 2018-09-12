# Setup Cinder Glance
class easystack::profile::cinder::glance (
    String $public_endpoint = $::easystack::config::public_endpoint,
) {

    include easystack

    class { 'cinder::glance':
        glance_api_servers => ["https://${public_endpoint}:9292"],

    }
}
