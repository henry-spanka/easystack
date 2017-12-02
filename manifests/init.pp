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
    String $database_root_password           = $easystack::params::database_root_password,
    String $management_network               = $easystack::params::management_network,
    String $rabbitmq_user_openstack_password = $easystack::params::rabbitmq_user_openstack_password,
    String $database_keystone_password       = $easystack::params::database_keystone_password,
    String $keystone_admin_token             = $easystack::params::keystone_admin_token,
    String $keystone_admin_password          = $easystack::params::keystone_admin_password,
    String $keystone_admin_email             = $easystack::params::keystone_admin_email,
    String $keystone_region                  = $easystack::params::keystone_region,
    String $database_glance_password         = $easystack::params::database_glance_password,
    String $keystone_glance_password         = $easystack::params::keystone_glance_password,
    String $keystone_nova_password           = $easystack::params::keystone_nova_password,
    String $database_nova_password           = $easystack::params::database_nova_password,
    String $keystone_nova_placement_password = $easystack::params::keystone_nova_placement_password,
    String $keystone_neutron_password        = $easystack::params::keystone_neutron_password,
    String $database_neutron_password        = $easystack::params::database_neutron_password,
    String $horizon_secret_key               = $easystack::params::horizon_secret_key,
    String $neutron_metadata_shared_secret   = $easystack::params::neutron_metadata_shared_secret,
    Array $controller_nodes                  = $easystack::params::controller_nodes,
    String $database_sstuser_password        = $easystack::params::database_sstuser_password,
    String $rabbitmq_erlang_cookie           = $easystack::params::rabbitmq_erlang_cookie,
    String $controller_vip                   = $easystack::params::controller_vip,
    String $database_status_password         = $easystack::params::database_status_password,
    String $user_hacluster_password          = $easystack::params::user_hacluster_password,
    Hash $keystone_fernet_keys               = $easystack::params::keystone_fernet_keys,
    Array $ceph_monitors                     = $easystack::params::ceph_monitors,
    String $ceph_fsid                        = $easystack::params::ceph_fsid,
    String $ceph_mon_key                     = $easystack::params::ceph_mon_key,
    String $ceph_admin_key                   = $easystack::params::ceph_admin_key,
    String $ceph_bootstrap_osd_key           = $easystack::params::ceph_bootstrap_osd_key,
    String $ceph_glance_key                  = $easystack::params::ceph_glance_key,
    String $ceph_cinder_key                  = $easystack::params::ceph_cinder_key,
    String $ceph_nova_key                    = $easystack::params::ceph_nova_key,
    String $ceph_cinder_secret_uuid          = $easystack::params::ceph_cinder_secret_uuid,
    String $ceph_cluster_network             = $easystack::params::ceph_cluster_network,
    String $ceph_public_network              = $easystack::params::ceph_public_network,
    String $database_cinder_password         = $easystack::params::database_cinder_password,
    String $keystone_cinder_password         = $easystack::params::keystone_cinder_password,
    String $glance_nfs_device                = $easystack::params::glance_nfs_device,
    Hash $keystone_credential_keys           = $easystack::params::keystone_credential_keys,
    String $management_interface             = $easystack::params::management_interface,
    String $public_interface                 = $easystack::params::public_interface,
    Array $provider_interface_mappings       = $easystack::params::provider_interface_mappings,
    Boolean $enable_stonith                  = $easystack::params::enable_stonith,
    String $filebeat_host                    = $easystack::params::filebeat_host,
    Array $admin_networks                    = $easystack::params::admin_networks,
    String $public_mgmt_vlan                 = $easystack::params::public_mgmt_vlan,
    String $public_vlan                      = $easystack::params::public_vlan,
    String $public_vip                       = $easystack::params::public_vip,
    String $public_vip_cidr                  = $easystack::params::public_vip_cidr,
    String $public_vip_gw                    = $easystack::params::public_vip_gw,
    String $public_endpoint                  = $easystack::params::public_endpoint,
    String $admin_endpoint                   = $easystack::params::admin_endpoint,
    String $public_endpoint_ssl_cert         = $easystack::params::public_endpoint_ssl_cert,
    String $admin_endpoint_ssl_cert          = $easystack::params::admin_endpoint_ssl_cert,
    String $haproxy_stats_password           = $easystack::params::haproxy_stats_password,
    String $nova_compute_ssh_private         = $easystack::params::nova_compute_ssh_private,
    String $nova_compute_ssh_public          = $easystack::params::nova_compute_ssh_public,
    String $rescue_image_id                  = $easystack::params::rescue_image_id,
) inherits easystack::params {
    include easystack::deps

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
        glance_nfs_device                => $glance_nfs_device,
        keystone_credential_keys         => $keystone_credential_keys,
        management_interface             => $management_interface,
        public_interface                 => $public_interface,
        provider_interface_mappings      => $provider_interface_mappings,
        enable_stonith                   => $enable_stonith,
        filebeat_host                    => $filebeat_host,
        admin_networks                   => $admin_networks,
        public_mgmt_vlan                 => $public_mgmt_vlan,
        public_vlan                      => $public_vlan,
        public_vip                       => $public_vip,
        public_vip_cidr                  => $public_vip_cidr,
        public_vip_gw                    => $public_vip_gw,
        public_endpoint                  => $public_endpoint,
        admin_endpoint                   => $admin_endpoint,
        public_endpoint_ssl_cert         => $public_endpoint_ssl_cert,
        admin_endpoint_ssl_cert          => $admin_endpoint_ssl_cert,
        haproxy_stats_password           => $haproxy_stats_password,
        nova_compute_ssh_private         => $nova_compute_ssh_private,
        nova_compute_ssh_public          => $nova_compute_ssh_public,
        rescue_image_id                  => $rescue_image_id,
    }
}
