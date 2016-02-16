# File::      <tt>params.pp</tt>
# Author::    S. Varrette, H. Cartiaux, V. Plugaru, S. Diehl aka. UL HPC Management Team (Hyacinthe.Cartiaux@uni.lu)
# Copyright:: Copyright (c) 2016 S. Varrette, H. Cartiaux, V. Plugaru, S. Diehl aka. UL HPC Management Team
# License::   Gpl-3.0
#
# ------------------------------------------------------------------------------
# You need the 'future' parser to be able to execute this manifest (that's
# required for the each loop below).
#
# Thus execute this manifest in your vagrant box as follows:
#
#      sudo puppet apply -t --parser future /vagrant/tests/params.pp
#
#

include 'openssl::params'

$names = ["ensure", "protocol", "port", "packagename"]

notice("openssl::params::ensure = ${openssl::params::ensure}")
notice("openssl::params::protocol = ${openssl::params::protocol}")
notice("openssl::params::port = ${openssl::params::port}")
notice("openssl::params::packagename = ${openssl::params::packagename}")

#each($names) |$v| {
#    $var = "openssl::params::${v}"
#    notice("${var} = ", inline_template('<%= scope.lookupvar(@var) %>'))
#}
