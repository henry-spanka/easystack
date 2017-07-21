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
    $keystone_admin_token             = $easystack::params::keystone_admin_token,
    $keystone_admin_password          = $easystack::params::keystone_admin_password,
    $keystone_admin_email             = $easystack::params::keystone_admin_email,
    $keystone_region                  = $easystack::params::keystone_region,
    $database_glance_password         = $easystack::params::database_glance_password,
    $keystone_glance_password         = $easystack::params::keystone_glance_password,
    $keystone_nova_password           = $easystack::params::keystone_nova_password,
    $database_nova_password           = $easystack::params::database_nova_password,
    $keystone_nova_placement_password = $easystack::params::keystone_nova_placement_password,
    $keystone_neutron_password        = $easystack::params::keystone_neutron_password,
    $database_neutron_password        = $easystack::params::database_neutron_password,
    $horizon_secret_key               = $easystack::params::horizon_secret_key,
    $controller_host                  = $easystack::params::controller_host,
    $neutron_provider_interface       = $easystack::params::neutron_provider_interface,
    $neutron_metadata_shared_secret   = $easystack::params::neutron_metadata_shared_secret,
    $controller_nodes                 = $easystack::params::controller_nodes,
    $database_sstuser_password        = $easystack::params::database_sstuser_password,
    $rabbitmq_erlang_cookie           = $easystack::params::rabbitmq_erlang_cookie,
    $controller_vip                   = $easystack::params::controller_vip,
    $database_status_password         = $easystack::params::database_status_password,
    $user_hacluster_password          = $easystack::params::user_hacluster_password,
    $keystone_fernet_keys             = $easystack::params::keystone_fernet_keys,
    $ceph_monitors                    = $easystack::params::ceph_monitors,
    $ceph_fsid                        = $easystack::params::ceph_fsid,
    $ceph_mon_key                     = $easystack::params::ceph_mon_key,
    $ceph_admin_key                   = $easystack::params::ceph_admin_key,
    $ceph_bootstrap_osd_key           = $easystack::params::ceph_bootstrap_osd_key,
    $ceph_glance_key                  = $easystack::params::ceph_glance_key,
    $ceph_cinder_key                  = $easystack::params::ceph_cinder_key,
    $ceph_nova_key                    = $easystack::params::ceph_nova_key,
    $ceph_cinder_secret_uuid          = $easystack::params::ceph_cinder_secret_uuid,
    $ceph_cluster_network             = $easystack::params::ceph_cluster_network,
    $ceph_public_network              = $easystack::params::ceph_public_network,
    $database_cinder_password         = $easystack::params::database_cinder_password,
    $keystone_cinder_password         = $easystack::params::keystone_cinder_password,
) inherits easystack::params {
    # Validate the parameters
    validate_string($database_root_password)
    validate_string($management_network)
    validate_string($rabbitmq_user_openstack_password)
    validate_string($database_keystone_password)
    validate_string($keystone_admin_token)
    validate_string($keystone_admin_password)
    validate_string($keystone_admin_email)
    validate_string($keystone_region)
    validate_string($database_glance_password)
    validate_string($keystone_glance_password)
    validate_string($keystone_nova_password)
    validate_string($database_nova_password)
    validate_string($keystone_nova_placement_password)
    validate_string($keystone_neutron_password)
    validate_string($database_neutron_password)
    validate_string($horizon_secret_key)
    validate_string($controller_host)
    validate_string($neutron_provider_interface)
    validate_string($neutron_metadata_shared_secret)
    validate_string($database_cinder_password)
    validate_string($keystone_cinder_password)

    if ($controller_nodes != undef) {
        validate_array($controller_nodes)
        validate_string($database_sstuser_password)
        validate_string($rabbitmq_erlang_cookie)
        validate_string($controller_vip)
        validate_string($database_status_password)
        validate_string($user_hacluster_password)
        validate_hash($keystone_fernet_keys)
    }

    if ($ceph_monitors != undef) {
        validate_array($ceph_monitors)
        validate_string($ceph_fsid)
        validate_string($ceph_mon_key)
        validate_string($ceph_admin_key)
        validate_string($ceph_bootstrap_osd_key)
        validate_string($ceph_glance_key)
        validate_string($ceph_cinder_key)
        validate_string($ceph_nova_key)
        validate_string($ceph_cinder_secret_uuid)
        validate_string($ceph_cluster_network)
        validate_string($ceph_public_network)
    }

    # Instaniate config class
    class { '::easystack::config':
        database_root_password           => $database_root_password,
        management_network               => $management_network,
        rabbitmq_user_openstack_password => $rabbitmq_user_openstack_password,
        database_keystone_password       => $database_keystone_password,
        keystone_admin_token             => $keystone_admin_token,
        keystone_admin_password          => $keystone_admin_password,
        keystone_admin_email             => $keystone_admin_email,
        keystone_region                  => $keystone_region,
        database_glance_password         => $database_glance_password,
        keystone_glance_password         => $keystone_glance_password,
        keystone_nova_password           => $keystone_nova_password,
        database_nova_password           => $database_nova_password,
        keystone_nova_placement_password => $keystone_nova_placement_password,
        keystone_neutron_password        => $keystone_neutron_password,
        database_neutron_password        => $database_neutron_password,
        horizon_secret_key               => $horizon_secret_key,
        controller_host                  => $controller_host,
        neutron_provider_interface       => $neutron_provider_interface,
        neutron_metadata_shared_secret   => $neutron_metadata_shared_secret,
        controller_nodes                 => $controller_nodes,
        database_sstuser_password        => $database_sstuser_password,
        rabbitmq_erlang_cookie           => $rabbitmq_erlang_cookie,
        controller_vip                   => $controller_vip,
        database_status_password         => $database_status_password,
        user_hacluster_password          => $user_hacluster_password,
        keystone_fernet_keys             => $keystone_fernet_keys,
        ceph_monitors                    => $ceph_monitors,
        ceph_fsid                        => $ceph_fsid,
        ceph_mon_key                     => $ceph_mon_key,
        ceph_admin_key                   => $ceph_admin_key,
        ceph_bootstrap_osd_key           => $ceph_bootstrap_osd_key,
        ceph_glance_key                  => $ceph_glance_key,
        ceph_cinder_key                  => $ceph_cinder_key,
        ceph_nova_key                    => $ceph_nova_key,
        ceph_cinder_secret_uuid          => $ceph_cinder_secret_uuid,
        ceph_cluster_network             => $ceph_cluster_network,
        ceph_public_network              => $ceph_public_network,
        database_cinder_password         => $database_cinder_password,
        keystone_cinder_password         => $keystone_cinder_password,
    }
}
