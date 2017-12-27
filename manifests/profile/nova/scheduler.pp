# Setup Nova Scheduler
class easystack::profile::nova::scheduler {
    # make sure the parameters are initialized
    include ::easystack

    include ::easystack::profile::nova

    class { '::nova::scheduler':
        discover_hosts_in_cells_interval => '300',
    }

    contain ::nova::scheduler

    class { '::nova::scheduler::filter':
        scheduler_default_filters => [
            'RetryFilter',
            'AvailabilityZoneFilter',
            'ComputeFilter',
            'ComputeCapabilitiesFilter',
            'ImagePropertiesFilter',
            'ServerGroupAntiAffinityFilter',
            'ServerGroupAffinityFilter',
            'AggregateInstanceExtraSpecsFilter',
        ],
    }

    contain ::nova::scheduler::filter

}
