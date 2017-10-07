# Disable Keystone Admin Token Authentication
class easystack::profile::keystone::disable_admin_token_auth (
    String $admin_endpoint = $::easystack::config::admin_endpoint,
    String $admin_password = $::easystack::config::keystone_admin_password,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::keystone

    file { '/root/openrc':
        ensure    => file,
        content   => epp(
            'easystack/keystone/openrc.epp',
            {
                'auth_url'      => "http://${admin_endpoint}:35357/v3",
                'auth_password' => $admin_password,
            }
        ),
        show_diff => false,
        owner     => 'root',
        group     => 'root',
        mode      => '0600', # Only root should be able to read the credentials
        tag       => 'openrc',
    }

    File['/root/openrc'] -> Ini_subsetting <| tag == 'disable-admin-token-auth' |>

    Keystone::Resource::Service_identity<||> -> Class['easystack::profile::keystone::disable_admin_token_auth']

    ini_subsetting { 'public_api/admin_token_auth':
        ensure     => absent,
        path       => '/etc/keystone/keystone-paste.ini',
        section    => 'pipeline:public_api',
        setting    => 'pipeline',
        subsetting => 'admin_token_auth',
        tag        => 'disable-admin-token-auth',
    }
    ini_subsetting { 'admin_api/admin_token_auth':
        ensure     => absent,
        path       => '/etc/keystone/keystone-paste.ini',
        section    => 'pipeline:admin_api',
        setting    => 'pipeline',
        subsetting => 'admin_token_auth',
        tag        => 'disable-admin-token-auth',
    }
    ini_subsetting { 'api_v3/admin_token_auth':
        ensure     => absent,
        path       => '/etc/keystone/keystone-paste.ini',
        section    => 'pipeline:api_v3',
        setting    => 'pipeline',
        subsetting => 'admin_token_auth',
        tag        => 'disable-admin-token-auth',
    }

    Ini_subsetting <| tag == 'disable-admin-token-auth' |>
    ~> Exec<| name == 'restart_keystone' |>

}
