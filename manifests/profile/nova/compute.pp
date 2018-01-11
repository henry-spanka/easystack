# Setup Nova Compute
class easystack::profile::nova::compute (
    String $listen_ip       = ip_for_network($::easystack::config::management_network),
    String $public_endpoint = $::easystack::config::public_endpoint,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    class { 'nova::compute':
        vnc_enabled                      => true,
        vncserver_proxyclient_address    => $listen_ip,
        neutron_enabled                  => true,
        resume_guests_state_on_host_boot => true,
    }

    contain nova::compute

    # lint:ignore:duplicate_params
    nova_config {
    'DEFAULT/enabled_apis':    value => ['osapi_compute', 'metadata'];
    'vnc/novncproxy_base_url': value => "https://${public_endpoint}:6080/vnc_auto.html";
    }
    # lint:endignore

}
