# Setup Haproxy SSL
class easystack::profile::haproxy::ssl (
    String $public_endpoint_ssl_cert = $::easystack::config::public_endpoint_ssl_cert,
    String $admin_endpoint_ssl_cert = $::easystack::config::admin_endpoint_ssl_cert,
) {
    # make sure the parameters are initialized
    include ::easystack

    file { '/etc/pki/tls/private/public_endpoint.pem':
        owner     => 'root',
        group     => 'haproxy',
        mode      => '0640',
        content   => $public_endpoint_ssl_cert,
        show_diff => false,
    }

    file { '/etc/pki/tls/private/admin_endpoint.pem':
        owner     => 'root',
        group     => 'haproxy',
        mode      => '0640',
        content   => $admin_endpoint_ssl_cert,
        show_diff => false,
    }

    Haproxy::Install['haproxy']
    -> Class['easystack::profile::haproxy::ssl']
    ~> Anchor['easystack::haproxy::install::end']

}
