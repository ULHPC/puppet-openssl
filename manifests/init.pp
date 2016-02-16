# File::      <tt>init.pp</tt>
# Author::    S. Varrette, H. Cartiaux, V. Plugaru, S. Diehl aka. UL HPC Management Team (Hyacinthe.Cartiaux@uni.lu)
# Copyright:: Copyright (c) 2016 S. Varrette, H. Cartiaux, V. Plugaru, S. Diehl aka. UL HPC Management Team
# License::   Gpl-3.0
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
        debian, ubuntu:         { include openssl::common::debian }
        redhat, fedora, centos: { include openssl::common::redhat }
        default: {
            fail("Module ${module_name} is not supported on ${::operatingsystem}")
        }
    }
}
