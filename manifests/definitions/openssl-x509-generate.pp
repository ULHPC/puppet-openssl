# File::      <tt>openssl-x509-generate.pp</tt>
# Author::    Sebastien Varrette (<Sebastien.Varrette@uni.lu>)
# Copyright:: Copyright (c) 2011 Sebastien Varrette (www[http://varrette.gforge.uni.lu])
# License::   GPLv3
#
# ------------------------------------------------------------------------------
# = Defines: openssl::x509::generate
#
# This definition can be used to generate a new X.509 certificate (this includes
# the private key and (1) the certicate if the self-signed parameter is set to
# true or (2) the certificate signing request (CSR) if the self-signed parameter
# is set to false.
# This is based on 'openssl req' command line that manages PKCS#10 X.509
# Certificate Signing Request (CSR).
# See http://www.openssl.org/docs/apps/req.html
#
# == Parameters:
#
# [*ensure*]
#   default to 'present', can be 'absent'. Ensure wether certif and its config
#   are present or not.
#
# [*$country*]
#   Certificate countryName
#   Default: 'LU'
#
# [*$state*]
#   Certificate stateOrProvinceName
#
# [*$locality*]
#   Certificate localityName
#   Default: 'Luxembourg'
#
# [*$organization*]
#   Certificate organizationName
#   Default: 'University of Luxembourg'
#
# [*$organizational_unit*]
#   Certificate organizationalUnitName
#   Default: 'Computer Science and Communication (CSC) Research Unit'
#
# [*$altnames*]
#   Certificate subjectAltName. Can be an array or a single string.
#
# [*$days*]
#   Certificate validity
#   Default: 365 days
#
# [*$commonname*]
#   Certificate CommonName
#   Default: the definition name
#
# [*$email*]
#   Certificate emailAddress. THIS PARAMETER SHOULD BE SET
#
# [*$basedir*]
#   The directory where the generated files (cnf, key, crt or csr) should be
#   placed. This directory MUST exist.
#   Default: '/etc/ssl/certs'
#
# [*$owner*]
#   Owner of the the generated files (cnf, key, crt or csr). The user MUST
#   exist.
#   Default: 'root'
#
# [*$group*]
#   Group owner of the the generated files (cnf, key, crt or csr). The group
#   MUST exist.
#   Default: 'root'
#
# [*$self_signed*]
#   Whether or not to generate a self signed certificate.
#   Set this to true if you don't want to deal with another certificate
#   authority, or just want to create a test certificate for yourself.  This is
#   similar to creating a certificate request, but creates a certificate instead
#   of a certificate request. Note that this is NOT the recommended way to
#   create a CA certificate.
#   Default: true
#
# [*key*]
#   Path to the private key for which you want to generate a certificate signing
#   request (CSR). Only useful in some very special cases where fom some reason
#   you created the SSL private key by other means than openssl::x509::generate
#   (for instance with openssl::ca::init) and want to generate the CSR
#   associated to this key. NOT COMPATIBLE WITH $self_signed == true
#
# == Requires:
#
# The class openssl should have been instanciated.
# $email SHOULD be provided
#
# == Sample usage:
#
#      include 'openssl'
#      openssl::x509::generate { 'foo.bar':
#          ensure => 'present',
#          country      => "LU",
#          organization => "University of Luxembourg",
#          organizational_unit => 'CSC',
#          commonname   => $fqdn,
#          base_dir     => "/var/www/ssl",
#          owner        => "www-data",
#          group        => 'www-data'
#      }
#
#  This will create files "foo.bar.cnf", "foo.bar.crt", "foo.bar.key" and
#  "foo.bar.csr" in /var/www/ssl/. All files will belong to user and group
#  "www-data". Those files can be used as is for apache, openldap and so on.
#
# == Warnings
#
# /!\ Always respect the style guide available
# here[http://docs.puppetlabs.com/guides/style_guide]
#
# [Remember: No empty lines between comments and class definition]
#
define openssl::x509::generate (
    $key                 = '',
    $config              = '',
    $email               = $openssl::params::email,
    $commonname          = '',
    $ensure              = 'present',
    $country             = $openssl::params::country,
    $state               = $openssl::params::state,
    $locality            = $openssl::params::locality,
    $organization        = $openssl::params::organization,
    $organizational_unit = $openssl::params::organizational_unit,
    $altnames            = '',
    $days                = $openssl::params::days,
    $basedir             = '/etc/ssl/certs',
    $owner               = $openssl::params::cert_basedir_owner,
    $group               = $openssl::params::cert_basedir_group,
    $mode                = $openssl::params::cert_basedir_mode,
    $self_signed         = true
)
{
    include openssl::params
    include openssl

    # $name is provided by define invocation
    $certname = $name
    $configfile = $config ? {
        ''      => "${basedir}/${certname}.cnf",
        default => "${config}"
    }
    $certfile   = "${basedir}/${certname}${openssl::params::cert_filename_suffix}"
    $csrfile    = "${basedir}/${certname}${openssl::params::csr_filename_suffix}"
    $keyfile = $key ? {
        ''      => "${basedir}/${certname}${openssl::params::key_filename_suffix}",
        default => "${key}"
    }

    $real_commonname = $commonname ? {
        ''      => "${fqdn}",
        default => $commonname
    }

    info ("Generation of a X.509 certificate via openssl::x509::generate (with ensure = ${ensure})")

    if ! ($ensure in [ 'present', 'absent' ]) {
        fail("openssl::x509::generate 'ensure' parameter must be set to either 'absent' or 'present'")
    }
    if  ($self_signed and ($key != '')) {
        fail("You cannot self-signed the key '${key}' provided to openssl::x509::generate")
    }

    if !defined( Package['openssl'] ){
        package { 'openssl':
            ensure => 'present'
        }
    }

    if !defined( File["${basedir}"]) {
        exec { "mkdir -p ${basedir}":
            path    => "/usr/bin:/usr/sbin/:/bin:/sbin",
            unless  => "test -d ${basedir}",
        }
        file { "${basedir}":
            ensure  => "directory",
            owner   => "${owner}",
            group   => "${group}",
            mode    => "${mode}",
            require => Exec["mkdir -p ${basedir}"]
        }
    }
    if !defined( File["${configfile}"]) {
        file { "$configfile":
            ensure  => "${ensure}",
            owner   => "${owner}",
            group   => "${group}",
            content => template("openssl/cert-req.cnf.erb"),
        }
    }

    case $ensure {
        present: {
            # Here openssl::x509::generate::ensure = 'present'
            $self_signed_opt = $self_signed ? {
                false   => '',
                default => '-x509'
            }
            $outfile = $self_signed ? {
                false   => "${csrfile}",
                default => "${certfile}"
            }
            $key_opts = $key ? {
                ''      => "-keyout ${keyfile}",
                default => "-key    ${keyfile}"
            }

            $creationlabel = $self_signed ? {
                false   => "create ${certname} Certificate Signing Request (CSR)",
                default => "create ${certname} certificate"
            }

            if $config == '' {
                File["$configfile"] {
                    notify => Exec["$creationlabel"]
                }
            }

            $cmd_generate_cert = "openssl req -new ${self_signed_opt} -nodes -config ${configfile} -out ${outfile} ${key_opts}"

            exec { "$creationlabel":
                command => "${cmd_generate_cert}",
                creates => "$outfile",
                unless  => "test -f ${certfile}",
                path    => "/usr/bin:/usr/sbin/:/bin:/sbin",
                require => [
                            File["$configfile"],
                            Package['openssl']
                            ]
            }

            # Change the mode and the owner of the key file
            exec { "chmod 0600 $keyfile":
                path    => "/usr/bin:/usr/sbin/:/bin:/sbin",
                onlyif  => "test -f ${keyfile}",
                require => Exec["$creationlabel"]
            }
            exec { "chown ${owner}:${group} ${keyfile} ${outfile}":
                path   => "/usr/bin:/usr/sbin/:/bin:/sbin",
                onlyif => [
                           "test -f ${keyfile}",
                           "test -f ${outfile}"
                           ],
                require => Exec["$creationlabel"]
            }



        }
        absent: {
            # Here openssl::x509::generate::ensure = 'absent'
            file { ["$configfile", "$keyfile", "$certfile" ]:
                ensure => "${ensure}"
            }

        }
        default: { err ( "Unknown ensure value: '${ensure}'" ) }
    }
}







