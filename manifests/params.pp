# Easystack parameters
class easystack::params {
    $database_root_password = undef
    $management_network = undef
    $rabbitmq_user_openstack_password = undef
    $database_keystone_password = undef
    $keystone_admin_token = undef
    $keystone_admin_password = undef
    $keystone_admin_email = undef
    $keystone_region = undef
    $database_glance_password = undef
    $keystone_glance_password = undef
    $keystone_nova_password = undef
    $database_nova_password = undef
    $keystone_nova_placement_password = undef
    $keystone_neutron_password = undef
    $database_neutron_password = undef
    $horizon_secret_key = undef
    $neutron_provider_interface = undef
    $neutron_metadata_shared_secret = undef
    $controller_nodes = undef
    $database_sstuser_password = undef
    $rabbitmq_erlang_cookie = undef
    $controller_vip = undef
    $database_status_password = undef
    $user_hacluster_password = undef
    $keystone_fernet_keys = undef
    $ceph_monitors = undef
    $ceph_fsid = undef
    $ceph_mon_key = undef
    $ceph_admin_key = undef
    $ceph_bootstrap_osd_key = undef
    $ceph_glance_key = undef
    $ceph_cinder_key = undef
    $ceph_nova_key = undef
    $ceph_cinder_secret_uuid = undef
    $ceph_cluster_network = undef
    $ceph_public_network = undef
    $database_cinder_password = undef
    $keystone_cinder_password = undef
}
