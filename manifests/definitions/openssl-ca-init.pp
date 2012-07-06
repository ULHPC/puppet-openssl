# File::      <tt>openssl-ca-init.pp</tt>
# Author::    Sebastien Varrette (<Sebastien.Varrette@uni.lu>)
# Copyright:: Copyright (c) 2012 Sebastien Varrette (www[http://varrette.gforge.uni.lu])
# License::   GPLv3
#
# ------------------------------------------------------------------------------
# = Defines: openssl::ca::init
#
# Initialize a CA using the Makefile and the openssl.cnf specially made for the
# CA (largelly inspired from the old sial.org element now available at
# http://novosial.org/openssl/ca/).
# All the certificate parameters (country, locality, organisation etc.) are
# automatically inherited from openssl::ca parameters.
#
# == Parameters:
#
# [*$commonname*]
#   CA Certificate CommonName. THIS PARAMETER SHOULD BE SET
#
# [*$email*]
#   CA Certificate emailAddress. THIS PARAMETER SHOULD BE SET
#
# [*$basedir*]
#   The directory where the generated files should be placed. This directory
#   MUST exist and corresponds normally to $name
#
# [*$templatedir*]
#   The directory where the reference Makefile is placed such that it is
#   sufficient to make a symbolic link to this makefile
#
# [*$owner*]
#   Owner of the the generated files. The user MUST
#   exist.
#   Default: 'root'
#
# [*$group*]
#   Group owner of the the generated files. The group
#   MUST exist.
#   Default: 'root'
#
# [*$mode*]
#   Mode to apply to the created files (Makefile & openssl.cnf)
#
# == Requires:
#
# The class openssl::ca should have been instanciated.
# $email SHOULD be provided
#
# == Sample usage:
#
#      include 'openssl::ca'
#  
#    openssl::ca::init { "/etc/certificates/CA":
#        commonname  => "My Personnal Root Authority",
#        email       => "my.mail@domain.org",
#        owner       => 'root',
#        group       => 'root',
#        mode        => '0600',
#        templatedir => '/etc/certificates/templates'
#    }
#
# == Warnings
#
# /!\ Always respect the style guide available
# here[http://docs.puppetlabs.com/guides/style_guide]
#
# [Remember: No empty lines between comments and class definition]
#
define openssl::ca::init (
    $email,
    $commonname,
    $basedir      = '',
    $owner        = $openssl::params::cert_basedir_owner,
    $group        = $openssl::params::cert_basedir_group,
    $mode         = '0644',
    $templatedir  = ''
)
{
    include openssl::params
    include openssl::ca

    # $name is provided at definition invocation and should be set to the basedir 
    $rootdir = $basedir ? {
        ''      => "${name}",
        default => "${rootdir}"
    }


    info ("Initialize the CA via openssl::ca::init (in ${rootdir})")

    # Prepare the Makefile (either a link to the one in the templatedir or a
    # regular file)
    if $templatedir != '' {
        file { "${rootdir}/Makefile":
            ensure  => 'link',
            target  => "${templatedir}/Makefile",
            require => File["${templatedir}/Makefile"]
        }
    }
    else
    {
        file { "${rootdir}/Makefile":
            ensure  => "${openssl::ca::ensure}",
            owner   => "${owner}",
            group   => "${group}",
            mode    => "${mode}",
            content => template("openssl/CA/Makefile.erb"),
            require => File["${rootdir}"],
        }
    }

    file { "${rootdir}/openssl.cnf":
        ensure  => "${openssl::ca::ensure}",
        owner   => "${owner}",
        group   => "${group}",
        mode    => "${mode}",
        content => template("openssl/CA/openssl-ca.cnf.erb"),
        require => File["${rootdir}"]
    }

    # initialize the CA by running make init
    exec { "Initialize the CA in ${rootdir}":
        path    => "/usr/bin:/usr/sbin/:/bin:/sbin",
        command => "make init",
        cwd     => "${rootdir}",
        require => [
                    File["${rootdir}/Makefile"],
                    File["${rootdir}/openssl.cnf"]
                    ],
        unless  => "test -d ${rootdir}/newcerts",
    }

}
