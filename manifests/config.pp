# Easystack config class
# private global parameters class. Do not use directly!
class easystack::config (
    $database_root_password = undef,
    $management_network     = undef,
    $rabbitmq_user_openstack_password = undef,
    $database_keystone_password = undef,
    $keystone_admin_token = undef,
    $keystone_admin_password = undef,
    $keystone_admin_email = undef,
    $keystone_region = undef,
    $database_glance_password = undef,
    $keystone_glance_password = undef,
    $keystone_nova_password = undef,
    $database_nova_password = undef,
    $keystone_nova_placement_password = undef,
    $keystone_neutron_password = undef,
    $database_neutron_password = undef,
    $horizon_secret_key = undef,
    $controller_host = undef,
    $neutron_network = undef,
    $neutron_provider_interface = undef,
    $neutron_metadata_shared_secret = undef,
    $controller_servers = undef,
    $database_sstuser_password = undef,
) {

}
