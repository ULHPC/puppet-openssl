# File::      <tt>openssl-ca.pp</tt>
# Author::    Sebastien Varrette (<Sebastien.Varrette@uni.lu>)
# Copyright:: Copyright (c) 2012 Sebastien Varrette (www[http://varrette.gforge.uni.lu])
# License::   GPLv3
#
# ------------------------------------------------------------------------------
# = Defines: openssl::ca
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
#      openssl::ca { '/etc/certificates':
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
define openssl::ca (
    $basedir             = '',
    $ensure              = $openssl::params::ensure,
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
{

    include openssl::params

    # $name is provided at definition invocation and should be set to the basedir
    $rootdir = $basedir ? {
        ''      => "${name}",
        default => "${basedir}"
    }
    
    info ("Configuring openssl::ca (with ensure = ${ensure}) in ${rootdir} (use Root CA = ${use_root_ca})")

    if !defined( Package['make'] ) {
        package { 'make':
            ensure => 'present'
        }
    }

    # The root directory of the CA
    if !defined( File["${rootdir}"] ){
        exec { "mkdir -p ${rootdir}":
            path    => "/usr/bin:/usr/sbin/:/bin:/sbin",
            unless  => "test -d ${rootdir}",
        }
        file { "${rootdir}":
            ensure  => "directory",
            owner   => "${owner}",
            group   => "${group}",
            mode    => "${mode}",
            require => Exec["mkdir -p ${rootdir}"]
        }
    }


    # Prepare the basic directories and variables (similar to the Puppet
    # built-in CA)  
    $templatedir   = "${rootdir}/.template"
    $cadir         = "${rootdir}/ca"
    $certdir       = "${rootdir}/certs"
    # $publickeydir  = "${rootdir}/public_keys"
    # $privatekeydir = "${rootdir}/private_keys"
    
    if $use_root_ca {
        $rootcadir  = "${rootdir}/rootCA"
        $ca_basedir = "${rootcadir}"
    }
    else
    {
        $ca_basedir = "${cadir}"
    }
    
    $cacertfile = "${rootdir}/ca${openssl::params::cert_filename_suffix}"
    #$cakeyfile  = "${rootdir}/ca${openssl::params::key_filename_suffix}"

    file { [ "${cadir}", "${certdir}", "${templatedir}" ]:
        ensure  => "directory",
        owner   => "${owner}",
        group   => "${group}",
        mode    => "${mode}",
        require => File["${rootdir}"]
    }

    # file { [ "${privatekeydir}" ]:
    #     ensure  => "directory",
    #     owner   => "${owner}",
    #     group   => "${group}",
    #     mode    => "0750",
    #     require => File["${rootdir}"]
    # }

    # prepare the template files
    file { "${templatedir}/Makefile":
        ensure  => "${ensure}",
        owner   => "${owner}",
        group   => "${group}",
        mode    => '0644',
        content => template("openssl/CA/Makefile.erb"),
        require => File["${templatedir}"],
    }
    file { "${templatedir}/openssl.cnf":
        ensure  => "${ensure}",
        owner   => "${owner}",
        group   => "${group}",
        mode    => '0644',
        source  => "puppet:///modules/openssl/ca/openssl.cnf",
        require => File["${templatedir}"],
    }

    # prepare the root CA
    if $use_root_ca {
        file { "${rootcadir}":
            ensure  => 'directory',
            owner   => 'root',
            group   => 'root',
            mode    => '0700',
            require => File["${rootdir}"]
        }
        init { "${rootcadir}":
            commonname  => "${root_ca_commonname}",
            email       => "${email}",
            owner       => 'root',
            group       => 'root',
            mode        => '0600',
            templatedir => "${templatedir}"
        }
    }

    # Prepare the CA directory
    init { "${cadir}":
        commonname  => "${ca_commonname}",
        email       => "${email}",
        owner       => "${owner}",
        group       => "${group}",
        mode        => '0600',
        templatedir => "${templatedir}"
    }

    # Sign the CA certificate with the Root CA
    if $use_root_ca {
        # Generate the new CSR for the Signing CA
        openssl::x509::generate { 'signing-ca':
            key         => "${cadir}/private/ca-key.pem",
            config      => "${cadir}/openssl.cnf",
            basedir     => "${cadir}",
            owner       => "${owner}",
            group       => "${group}",
            self_signed => false,
            require     => Openssl::Ca::Init["${cadir}"]
        }
        # ... And sign it by the Root CA
        openssl::ca::sign { 'signing-ca':
            basedir => "${cadir}",
            cadir   => "${rootcadir}",
            create_signing_authority  => true,
            require => Openssl::X509::Generate['signing-ca']
        }
        # # And replace the ca-cert.pem file of the Signing CA
        exec { "rm -f ${cadir}/ca-cert.pem":
            path    => "/usr/bin:/usr/sbin/:/bin:/sbin",
            cwd     => "${cadir}",
            onlyif  => "test -f ${cadir}/ca-cert.pem",
            require => Openssl::Ca::Sign['signing-ca']
        }
        file { "${cadir}/ca-cert.pem":
            ensure => 'link',
            target => "signing-ca${openssl::params::cert_filename_suffix}",
            require => Exec["rm -f ${cadir}/ca-cert.pem"]
        }
        $cert_requires = [ Openssl::X509::Generate["$fqdn"], Openssl::Ca::Sign[ 'signing-ca' ] ]
    }
    else
    {
       $cert_requires = [ Openssl::X509::Generate["$fqdn"], Openssl::Ca::Init["${cadir}"] ]
    }


    # Add the link to the (root) CA certificate
    file { "${cacertfile}":
        ensure  => 'link',
        target  => "${ca_basedir}/ca-cert.pem",
        require => Openssl::Ca::Init["${cadir}"]
    }

    file { "${certdir}/ca.pem":
        ensure  => 'link',
        target  => "${cacertfile}",
        require => File["${certdir}"]
    }

    # Create the certficiate for the current host:
    openssl::x509::generate { "$fqdn":
        email       => "hpc-sysadmins@uni.lu",
        ensure      => "${openssl::ca::ensure}",
        owner       => "${openssl::ca::owner}",
        group       => "${openssl::ca::group}",
        basedir     => "${certdir}",
        self_signed => false
    }

    # ... And sign it with the Signing CA
    openssl::ca::sign { "$fqdn":
        basedir => "${certdir}",
        owner   => "${openssl::ca::owner}",
        group   => "${openssl::ca::group}",
        cadir   => "${cadir}",
        require => $cert_requires
    }
}

# ------------------------------------------------------------------------------
# = Class: openssl::ca::debian
#
# Specialization class for Debian systems
class openssl::ca::debian inherits openssl::ca::common { }

# ------------------------------------------------------------------------------
# = Class: openssl::ca::redhat
#
# Specialization class for Redhat systems
class openssl::ca::redhat inherits openssl::ca::common { }







