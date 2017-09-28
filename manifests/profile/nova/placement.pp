# Setup Nova Placement
class easystack::profile::nova::placement (
    String $vip                = $::easystack::config::controller_vip,
    String $placement_password = $::easystack::config::keystone_nova_placement_password,
    String $region             = $::easystack::config::keystone_region,
) {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    class { 'nova::placement':
        os_region_name      => $region,
        project_domain_name => 'default',
        project_name        => 'services',
        auth_type           => 'password',
        auth_url            => "http://${vip}:35357/v3",
        username            => 'placement',
        password            => $placement_password,
    }

    contain nova::placement

}
