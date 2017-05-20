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
    $database_keystone_password_hash  = $easystack::params::database_keystone_password_hash,
) inherits easystack::params {
    # Validate the parameters
    validate_string($database_root_password)
    validate_string($management_network)
    validate_string($rabbitmq_user_openstack_password)
    validate_string($database_keystone_password_hash)

    # Instaniate config class
    class { '::easystack::config':
        database_root_password           => $database_root_password,
        management_network               => $management_network,
        rabbitmq_user_openstack_password => $rabbitmq_user_openstack_password,
        database_keystone_password_hash  => $database_keystone_password_hash,
    }
}
