# Class: easystack
# ===========================
#
# Manage your OpenStack environment using Puppet and easystack with ease.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'easystack':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Henry Spanka <henry@myvirtualserver.de>
#
# Copyright
# ---------
#
# Copyright 2017 Henry Spanka, unless otherwise noted.
#
class easystack (
    $database_root_password           = $easystack::params::database_root_password,
    $management_network               = $easystack::params::management_network,
    $rabbitmq_user_openstack_password = $easystack::params::rabbitmq_user_openstack_password,
    $database_keystone_password       = $easystack::params::database_keystone_password,
    $database_keystone_password_hash  = $easystack::params::database_keystone_password_hash,
    $keystone_admin_token             = $easystack::params::keystone_admin_token,
    $keystone_admin_password          = $easystack::params::keystone_admin_password,
    $keystone_admin_email             = $easystack::params::keystone_admin_email,
    $keystone_region                  = $easystack::params::keystone_region,
    $database_glance_password         = $easystack::params::database_glance_password,
    $database_glance_password_hash    = $easystack::params::database_glance_password_hash,
    $keystone_glance_password         = $easystack::params::keystone_glance_password,
) inherits easystack::params {
    # Validate the parameters
    validate_string($database_root_password)
    validate_string($management_network)
    validate_string($rabbitmq_user_openstack_password)
    validate_string($database_keystone_password)
    validate_string($database_keystone_password_hash)
    validate_string($keystone_admin_token)
    validate_string($keystone_admin_password)
    validate_string($keystone_admin_email)
    validate_string($keystone_region)
    validate_string($database_glance_password)
    validate_string($database_glance_password_hash)
    validate_string($keystone_glance_password)

    # Instaniate config class
    class { '::easystack::config':
        database_root_password           => $database_root_password,
        management_network               => $management_network,
        rabbitmq_user_openstack_password => $rabbitmq_user_openstack_password,
        database_keystone_password       => $database_keystone_password,
        database_keystone_password_hash  => $database_keystone_password_hash,
        keystone_admin_token             => $keystone_admin_token,
        keystone_admin_password          => $keystone_admin_password,
        keystone_admin_email             => $keystone_admin_email,
        keystone_region                  => $keystone_region,
        database_glance_password         => $database_glance_password,
        database_glance_password_hash    => $database_glance_password_hash,
        keystone_glance_password         => $keystone_glance_password,
    }
}
