# File::      <tt>openssl-ca.pp</tt>
# Author::    Sebastien Varrette (<Sebastien.Varrette@uni.lu>)
# Copyright:: Copyright (c) 2012 Sebastien Varrette (www[http://varrette.gforge.uni.lu])
# License::   GPLv3
#
# ------------------------------------------------------------------------------
# = Class: openssl::ca
#
# Configure and manage a Certificate Authority (CA), typically to initiate a
# chain of trust.
#
# == Parameters:
#
# $ensure:: *Default*: 'present'. Ensure the presence (or absence) of
#     openssl::ca
# $basedir:: *Default*: '/etc/certificates'. The basedir where the CA will be
#     created (in the CA directory typically)
# $country:: *Default*: 'LU'
#
#
#
# == Actions:
#
# Install and configure openssl::ca
#
# == Requires:
#
# n/a
#
# == Sample usage:
#
#     import openssl::ca
#
# You can then specialize the various aspects of the configuration,
# for instance:
#
#      class { 'openssl::ca':
#          ensure => 'present'
#      }
#
# == Warnings
#
# /!\ Always respect the style guide available
# here[http://docs.puppetlabs.com/guides/style_guide]
#
# [Remember: No empty lines between comments and class definition]
#
class openssl::ca (
    $ensure              = $openssl::params::ensure,
    $basedir             = $openssl::params::cert_basedir,
    $commonname          = $openssl::params::ca_commonname,
    $country             = $openssl::params::country,
    $state               = $openssl::params::state,
    $locality            = $openssl::params::locality,
    $organization        = $openssl::params::organization,
    $organizational_unit = $openssl::params::organizational_unit,
    $days                = $openssl::params::ca_days,
    $email               = $openssl::params::email,
    $owner               = $openssl::params::cert_basedir_owner,
    $group               = $openssl::params::cert_basedir_group,
    $mode                = $openssl::params::cert_basedir_mode,
    $ca_revocation_url   = $openssl::params::ca_revocation_url,
    $use_root_ca         = $openssl::params::use_root_ca,
    $root_ca_commonname  = $openssl::params::root_ca_commonname
)
inherits openssl::params
{

    info ("Configuring openssl::ca (with ensure = ${ensure}) in ${basedir} (use Root CA = ${use_root_ca})")

    if ! ($ensure in [ 'present', 'absent' ]) {
        fail("openssl::ca 'ensure' parameter must be set to either 'absent' or 'present'")
    }

    case $::operatingsystem {
        debian, ubuntu:         { include openssl::ca::common::debian }
        redhat, fedora, centos: { include openssl::ca::common::redhat }
        default: {
            fail("Module ${module_name} is not supported on ${::operatingsystem}")
        }
    }
}
