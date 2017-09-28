# Setup Nova Compute
class easystack::profile::nova::compute (
    String $listen_ip       = ip_for_network($::easystack::config::management_network),
    String $vip             = $::easystack::config::controller_vip,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    class { 'nova::compute':
        vnc_enabled                   => true,
        vncserver_proxyclient_address => $listen_ip,
        neutron_enabled               => true,
    }

    contain nova::compute

    # lint:ignore:duplicate_params
    nova_config {
    'DEFAULT/enabled_apis':    value => ['osapi_compute', 'metadata'];
    'vnc/novncproxy_base_url': value => "http://${vip}:6080/vnc_auto.html";
    }
    # lint:endignore

}
