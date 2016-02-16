#! /bin/bash
################################################################################
# generate-ssl-cert.sh - Generate an SSL certificate for a given virtual host
# Creation : 13 Sep 2011
# Time-stamp: <Tue 2011-09-13 21:02 svarrette>
#
# Copyright (c) 2011 Sebastien Varrette <Sebastien.Varrette@uni.lu>
#               http://varrette.gforge.uni.lu
#
# Description : see the print_help function or launch 'generate-ssl-cert.sh --help'
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

### Global variables
VERSION=0.1
COMMAND=`basename $0`
VERBOSE=""
DEBUG=""
SIMULATION=""

### displayed colors
COLOR_GREEN="\033[0;32m"
COLOR_RED="\033[0;31m"
COLOR_YELLOW="\033[0;33m"
COLOR_VIOLET="\033[0;35m"
COLOR_CYAN="\033[0;36m"
COLOR_BOLD="\033[1m"
COLOR_BACK="\033[0m"

### Local variables
OUTPUTDIR=.
DAYS=365
HOSTNAME=localhost


#######################
### print functions ###
#######################

####
# print version of this program
##
print_version() {
    cat <<EOF
This is $COMMAND version "$VERSION".
Copyright (c) 2011 Sebastien Varrette  (http://varrette.gforge.uni.lu)
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
EOF
}

####
# print help
##
print_help() {
    cat <<EOF
NAME
    $COMMAND --

SYNOPSIS
    $COMMAND [-V | -h]
    $COMMAND [--debug] [-v] [-n] --hostname hostname -f opensslconfigfile -o outputdir --days days

DESCRIPTION
    $COMMAND facilitate the automatic generation of SSL certificates

OPTIONS
    --debug
        Debug mode. Causes $COMMAND to print debugging messages.
    -h --help
        Display a help screen and quit.
    --hostname HOSTNAME
        Hostname to be used for the certificate name (\$hostname.crt is created)
    --days DAYS
        Expiration date of the certificate in days
    -o --outputdir DIR
        Generate the certioficate in the outputdir
    -f | --configfile FILENAME
        Use this file as template for the default configuration of SSL
    -n --dry-run
        Simulation mode.
    -v --verbose
        Verbose mode.
    -V --version
        Display the version number then quit.

AUTHOR
    Sebastien Varrette <Sebastien.Varrette@uni.lu>
    Web page: http://varrette.gforge.uni.lu

REPORTING BUGS
    Please report bugs to <Sebastien.Varrette@uni.lu>

COPYRIGHT
    This is free software; see the source for copying conditions.  There is
    NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR
    PURPOSE.

SEE ALSO
    Other scripts are available on my web site http://varrette.gforge.uni.lu
EOF
}

######
# Print information in the following form: '[$2] $1' ($2=INFO if not submitted)
# usage: info text [title]
##
info() {
    [ -z "$1" ] && print_error_and_exit "[$FUNCNAME] missing text argument"
    local text=$1
    local title=$2
    # add default title if not submitted but don't print anything
    [ -n "$text" ] && text="${title:==>} $text"
    echo -e $text
}
debug()   { [ -n "$DEBUG"   ] && info "$1" "[${COLOR_YELLOW}DEBUG${COLOR_BACK}]"; }
verbose() { [ -n "$VERBOSE" ] && info "$1"; }
error()   { info "$1" "[${COLOR_RED}ERROR${COLOR_BACK}]"; }
warning() { info "$1" "[${COLOR_VIOLET}WARNING${COLOR_BACK}]"; }
print_error_and_exit() {
    local text=$1
    [ -z "$1" ] && text=" Bad format"
    error  "$text. '$COMMAND -h' for help."
    exit 1
}
#####
# print the strings [ OK ] or [ FAILED ] or [ FAILED ]\n$1
##
print_ok()     { echo -e "[   ${COLOR_GREEN}OK${COLOR_BACK}   ]"; }
print_failed() { echo -e "[ ${COLOR_RED}FAILED${COLOR_BACK} ]"; }
print_failed_and_exit() {
    print_failed
    [ ! -z "$1" ] && echo "$1"
    exit 1
}

#########################
### toolbox functions ###
#########################

#####
# execute a local command
# usage: execute command
###
execute() {
    [ $# -eq 0 ] && print_error_and_exit "[$FUNCNAME] missing command argument"
    debug "[$FUNCNAME] $*"
    [ -n "${SIMULATION}" ] && echo "(simulation) $*" || eval $*
    local exit_status=$?
    debug "[$FUNCNAME] exit status: $exit_status"
    return $exit_status
}

####
# ask to continue. exit 1 if the answer is no
# usage: really_continue text
##
really_continue() {
    echo -e -n "[${COLOR_VIOLET}WARNING${COLOR_BACK}] $1 Are you sure you want to continue? [Y|n] "
    read ans
    case $ans in
        n*|N*) exit 1;;
    esac
}

#####
# Check availability of binaries passed as arguments on the current system
# usage: check_bin prog1 prog2 ...
##
check_bin() {
    [ $# -eq 0 ] && print_error_and_exit "[$FUNCNAME] missing argument"
    for appl in $*; do
        echo -n -e "=> checking availability of the command '$appl' on your system \t"
        local tmp=`which $appl`
        [ -z "$tmp" ] && print_failed_and_exit "Please install $appl or check \$PATH." || print_ok
    done
}

################################################################################
################################################################################
#[ $UID -gt 0 ] && print_error_and_exit "You must be root to execute this script (current uid: $UID)"

# Check for required argument
#[ $# -eq 0 ] && print_error_and_exit

# Check for options
while [ $# -ge 1 ]; do
    case $1 in
        -h | --help)    print_help;        exit 0;;
        -V | --version) print_version;     exit 0;;
        --hostname)     HOSTNAME=$1;       shift;;
        --days)         DAYS=$1;           shift;;
        -f | --configfile) CONFIGFILE=$1;  shift;;
        -o | --outputdir)  OUTPUTDIR=$1;   shift;;
        --debug)        
            DEBUG="--debug";
            VERBOSE="--verbose";;
        -v | --verbose)  VERBOSE="--verbose";;
        -n | --dry-run)  SIMULATION="--dry-run";;
    esac
    shift
done

# TODO check that the variables are correctly set
info "generating an OpenSSL certificate for hostname ${HOSTNAME}"

# In particular, CONFIG should be valid

export RANDFILE=/dev/random

if [ ! -e ${OUTPUTDIR}/${HOSTNAME}.crt ] || [ ! -e ${OUTPUTDIR}/${HOSTNAME}.key ]; then
  execute "openssl req -config ${CONFIGFILE} -new -x509 -nodes -days ${DAYS} -out ${OUTPUTDIR}/${HOSTNAME}.crt -keyout ${OUTPUTDIR}/${HOSTNAME}.key"
  [ "$?" -ne "0" ] && print_error_and_exit "openssl create certificate FAILED"
  execute "chmod 600 ${OUTPUTDIR}/${HOSTNAME}.key"
fi

execute "openssl req -new -key ${OUTPUTDIR}/${HOSTNAME}.key -config ${CONFIGFILE} > ${OUTPUTDIR}/${HOSTNAME}.csr"
[ "$?" -ne "0" ] && print_error_and_exit "openssl req certificate FAILED"

