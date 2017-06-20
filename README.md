# easystack

[OpenStack]: https://www.openstack.org

[Puppet module]: https://docs.puppetlabs.com/puppet/latest/reference/modules_fundamentals.html

[Chrony]: https://chrony.tuxfamily.org
[MariaDB]: https://mariadb.com
[RabbitMQ]: https://www.rabbitmq.com
[Memcached]: https://memcached.org
[Apache]: https://httpd.apache.org
[Selinux]: https://wiki.centos.org/HowTos/SELinux
[Firewalld]: http://www.firewalld.org
[Pacemaker]: http://clusterlabs.org
[HAProxy]: https://www.haproxy.org
[Sysctl]: https://www.centos.org/docs/4/4.5/Reference_Guide/s1-proc-sysctl.html
[Galera]: http://galeracluster.com
[/etc/services]: https://www.lifewire.com/what-is-etc-services-2196940
[Ceph]: http://ceph.com

[Keystone]: https://docs.openstack.org/developer/keystone/
[Glance]: https://docs.openstack.org/developer/glance/
[Nova]: https://docs.openstack.org/developer/nova/
[Neutron]: https://docs.openstack.org/developer/neutron/
[Horizon]: https://docs.openstack.org/developer/horizon/
[Cinder]: https://docs.openstack.org/developer/cinder/

[metadata.json]: metadata.json

[`easystack`]: manifests/init.pp

[Foreman]: https://theforeman.org

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with easystack](#setup)
    * [What easystack affects](#what-easystack-affects)
    * [Beginning with easystack](#beginning-with-easystack)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

[OpenStack] is a free platform for cloud computing. The deployment process
requires a deep understanding of the OpenStack services or individual projects.
This [Puppet module] tries to simplify the process of deploying and maintaining
an [OpenStack] cloud and it's individual projects.

## Setup

### What easystack affects

Easystack maintains a complete [OpenStack] cloud and affects the following
services:

* Basic Services:
    * [Chrony]
    * [MariaDB]
    * [RabbitMQ]
    * [Memcached]
    * [Apache]
    * [Selinux]
    * [Firewalld]
    * [Sysctl]
    * [/etc/services]


* HA Services:
    * [Pacemaker]
    * [HAProxy]
    * [Galera]


* Storage Services:
    * [Ceph]


* OpenStack Services:
    * [Keystone]
    * [Glance]
    * [Nova]
    * [Neutron]
    * [Horizon]
    * [Cinder]


* Puppet Module Dependencies can be viewed in [metadata.json]

### Beginning with easystack

In order to configure OpenStack first we need to declare the [`easystack`] class
to initialize any parameters:

``` puppet
class { 'easystack':
    parameter1 => value1,
    parameter2 => value2,
}
```

At the moment there are many required parameters. Information can be obtained in
the [`easystack`] class.

This module is compatible with [Foreman] to allow easy deployment of nodes
including OS installation.


## Usage

This section is where you describe how to customize, configure, and do the
fancy stuff with your module here. It's especially helpful if you include usage
examples and code samples for doing things with your module.

## Reference

Here, include a complete list of your module's classes, types, providers,
facts, along with the parameters for each. Users refer to this section (thus
the name "Reference") to find specific details; most users don't read it per
se.

## Limitations

This module is currently compatible with the following Operating Systems:

* CentOS 7

## Development

Since your module is awesome, other users will want to play with it. Let them
know what the ground rules for contributing are.
