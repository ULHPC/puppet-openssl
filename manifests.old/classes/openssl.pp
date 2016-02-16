# File::      <tt>openssl.pp</tt>
# Author::    Sebastien Varrette (Sebastien.Varrette@uni.lu)
# Copyright:: Copyright (c) 2011 Sebastien Varrette
# License::   GPLv3
#
# ------------------------------------------------------------------------------
# = Class: openssl
#
# Configure OpenSSL and manage X509 certificates (generation etc.)
#
# == Parameters:
#
# $ensure:: *Default*: 'present'. Ensure the presence (or absence) of openssl
#
# == Actions:
#
# Install and configure openssl
#
# == Requires:
#
# n/a
#
# == Sample Usage:
#
#     import openssl
#
# You can then specialize the various aspects of the configuration,
# for instance:
#
#         class { 'openssl':
#             ensure => 'present'
#         }
#
# == Warnings
#
# /!\ Always respect the style guide available
# here[http://docs.puppetlabs.com/guides/style_guide]
#
#
# [Remember: No empty lines between comments and class definition]
#
class openssl( $ensure = $openssl::params::ensure ) inherits openssl::params
{
    info ("Configuring openssl (with ensure = ${ensure})")

    if ! ($ensure in [ 'present', 'absent' ]) {
        fail("openssl 'ensure' parameter must be set to either 'absent' or 'present'")
    }

    case $::operatingsystem {
        debian, ubuntu:         { include openssl::debian }
        redhat, fedora, centos: { include openssl::redhat }
        default: {
            fail("Module ${module_name} is not supported on ${operatingsystem}")
        }
    }
}

# ------------------------------------------------------------------------------
# = Class: openssl::common
#
# Base class to be inherited by the other openssl classes
#
# Note: respect the Naming standard provided here[http://projects.puppetlabs.com/projects/puppet/wiki/Module_Standards]
class openssl::common {

    # Load the variables used in this module. Check the openssl-params.pp file
    require openssl::params

    package { 'openssl':
        name   => $openssl::params::packagename,
        ensure => $openssl::ensure,
    }

    if $openssl::params::utils_packages != [] {
        package { $openssl::params::utils_packages:
            ensure  => $openssl::ensure,
        }
    }

    # The script used to generate X.509 certificates
    file { $openssl::params::generate_ssl_cert:
        source  => 'puppet:///modules/openssl/generate-ssl-cert.sh',
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        ensure  => $openssl::ensure,
        require => Package['openssl']
    }

}


# ------------------------------------------------------------------------------
# = Class: openssl::debian
#
# Specialization class for Debian systems
class openssl::debian inherits openssl::common { }

# ------------------------------------------------------------------------------
# = Class: openssl::redhat
#
# Specialization class for Redhat systems
class openssl::redhat inherits openssl::common { }



