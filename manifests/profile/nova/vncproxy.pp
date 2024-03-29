# Setup Nova VNCProxy
class easystack::profile::nova::vncproxy (
    String $listen_ip       = ip_for_network($::easystack::config::management_network),
    String $public_endpoint = $::easystack::config::public_endpoint,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    include ::firewalld

    firewalld_port { 'Allow nova vncproxy on port 6080 tcp - zone=internal':
        ensure   => present,
        zone     => 'internal',
        port     => 6080,
        protocol => 'tcp',
        tag      => 'nova-firewall',
        before   => Service['nova-vncproxy'],
    }

    firewalld_port { 'Allow nova vncproxy on port 6080 tcp - zone=public_mgmt':
        ensure   => present,
        zone     => 'public_mgmt',
        port     => 6080,
        protocol => 'tcp',
        tag      => 'nova-firewall',
        before   => Service['nova-vncproxy'],
    }

    include ::nova::deps
    include ::nova::params

    # See http://nova.openstack.org/runnova/vncconsole.html for more details.

    nova_config {
        'vnc/novncproxy_host': value => $listen_ip;
        'vnc/novncproxy_port': value => 6080;
    }

    nova::generic_service { 'vncproxy':
        enabled        => true,
        manage_service => true,
        package_name   => $::nova::params::vncproxy_package_name,
        service_name   => $::nova::params::vncproxy_service_name,
        ensure_package => 'present',
    }

    # lint:ignore:duplicate_params
    nova_config {
        'vnc/enabled':                       value => true;
        'vnc/vncserver_listen':              value => $listen_ip;
        'vnc/vncserver_proxyclient_address': value => $public_endpoint;
        'vnc/novncproxy_base_url':           value => "https://${public_endpoint}:6080/vnc_auto.html";
    }
    # lint:endignore

}
