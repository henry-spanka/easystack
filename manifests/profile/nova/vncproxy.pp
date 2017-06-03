# Setup Nova VNCProxy
class easystack::profile::nova::vncproxy (
    String $listen_ip = ip_for_network($::easystack::config::management_network),
    String $vip       = $::easystack::config::controller_vip,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    include ::firewalld

    firewalld_port { 'Allow nova vncproxy on port 6080 tcp':
        ensure   => present,
        zone     => 'public',
        port     => 6080,
        protocol => 'tcp',
        tag      => 'nova-firewall',
        before   => Service['nova-vncproxy'],
    }

    class { 'nova::vncproxy':
        host => $listen_ip,
    }

    # lint:ignore:duplicate_params
    nova_config {
        'vnc/enabled':                       value => true;
        'vnc/vncserver_listen':              value => $listen_ip;
        'vnc/vncserver_proxyclient_address': value => $vip;
    }
    # lint:endignore

}
