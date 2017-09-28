# Setup Keystone Admin Role
class easystack::profile::keystone::roles::admin (
    String $admin_email    = $::easystack::config::keystone_admin_email,
    String $admin_password = $::easystack::config::keystone_admin_password,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::keystone

    class { 'keystone::roles::admin':
        email    => $admin_email,
        password => $admin_password,
    }

    contain keystone::roles::admin

    keystone_role { 'user':
        ensure  => present,
    }

}
