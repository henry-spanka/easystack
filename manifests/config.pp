# Easystack config class
# private global parameters class. Do not use directly!
class easystack::config (
    $database_root_password = undef,
    $management_network     = undef,
    $rabbitmq_user_openstack_password = undef,
    $database_keystone_password = undef,
    $database_keystone_password_hash = undef,
    $keystone_admin_token = undef,
    $keystone_admin_password = undef,
    $keystone_admin_email = undef,
    $keystone_region = undef,
    $database_glance_password = undef,
    $database_glance_password_hash = undef,
    $keystone_glance_password = undef,
    $keystone_nova_password = undef,
    $database_nova_password = undef,
    $database_nova_password_hash = undef,
    $keystone_nova_placement_password = undef,
    $keystone_neutron_password = undef,
    $database_neutron_password = undef,
    $database_neutron_password_hash = undef,
) {

}
