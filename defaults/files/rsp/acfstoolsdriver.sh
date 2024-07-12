#!/bin/sh
#
#
# acfstoolsdriver.sh
#
# Copyright (c) 2009, 2015, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      acfstoolsdriver - front end for the Perl scripts that do the work.
#
#    DESCRIPTION
#      common driver for:
#        acfsload, acfsroot, acfsregistrymount,
#        acfssinglefsmount, acfsdriverstate.
#
#    NOTES
#      This wrapper program supports Linux/Unix platforms.
#
#      ORA_CRS_HOME and ORACLE_HOME have been exported by the caller
#      (see DESCRIPTION). They are NOT inherited from the shell.
#
#
#############################################################################

# One echo to just the console.
CLSECHO="$ORA_CRS_HOME/bin/clsecho -p usm -f acfs  -c err "
# One echo to the log, with timestamps.
CLSECHOTL="$ORA_CRS_HOME/bin/clsecho -p usm -f acfs -l -c err -t -n"
SED=/bin/sed
PATH=/bin:/usr/bin:/usr/sbin:/sbin:$PATH
PLATFORM=`uname`

# Add Solaris32 backward compatibility for LD_LIBRARY_PATH.  This extra
# path is used for Solaris64 Oracle homes that come with a Solaris32
# Perl build.
LD_LIBRARY_PATH="${ORACLE_HOME}/lib:${LD_LIBRARY_PATH}"
LD_LIBRARY_PATH="${ORACLE_HOME}/lib32:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH

# AIX uses LIBPATH, not LD_LIBRARY_PATH.
if [ "${PLATFORM}" = "AIX" ] ; then
  LIBPATH="${ORACLE_HOME}/lib:${LIBPATH}"
  export LIBPATH
fi

# HP-UX uses SHLIB_PATH, not LD_LIBRARY_PATH.
if [ "${PLATFORM}" = "HP-UX" ] ; then
  SHLIB_PATH="${ORACLE_HOME}/lib32:${SHLIB_PATH}"
  export SHLIB_PATH
fi

# the basename of the command that the user entered
CMD=$1

# Set path to Perl.
PERLBIN="${ORACLE_HOME}/perl/bin/perl"

if [ ! -r $PERLBIN ] || [ ! -x $PERLBIN ] ; then
  # 9207: "The user this command is executing as does not have permission 
  # to execute Perl in '%s'"
  ${CLSECHO} -m 9207 $PERLBIN
  ${CLSECHOTL} -m 9207 $PERLBIN
  if [ $CMD = "acfsdriverstate" ] ; then
    # 9211: usage: %s [-h] [-orahome <home_path>]
    # {installed | loaded | version | supported} [-s]
    ${CLSECHO} -m 9211 $CMD
    ${CLSECHOTL} -m 9211 $CMD
  else
    # 9130: "Root access required."
    ${CLSECHO} -m 9130
    ${CLSECHOTL} -m 9130
  fi
  exit 1
fi

# Get Perl version.
PERLV=`${PERLBIN} -e 'printf "%vd", $^V'`

# Set PERLINC, which is a list of -I options passed to the perl
# interpreter, telling perl where to look for modules.
PERLINC="-I ${ORACLE_HOME}/perl/lib/${PERLV}"
PERLINC="${PERLINC} -I ${ORACLE_HOME}/perl/lib/site_perl/${PERLV}"

# if the OSD module is not found, the platform is not supported
if [ "$CMD" != "acfsreplcrs" ] ; then
  if [ ! -r $ORA_CRS_HOME/lib/osds_${CMD}.pm ] ; then
    # 9125: "ADVM/ACFS is not supported on $PLATFORM."
    ${CLSECHO} -m 9125 $PLATFORM
    ${CLSECHOTL} -m 9125 $PLATFORM
    exit 1
  fi
fi

PERLINC="${PERLINC} -I ${ORA_CRS_HOME}/lib"
CMD_LOC="${ORA_CRS_HOME}/lib/${CMD}.pl"

# Build command to execute the tool.
RUNTHIS="${PERLBIN} -w ${PERLINC} ${CMD_LOC}"

# Now run command with all arguments!
#exec ${RUNTHIS} $@
exit 0
# Should never get here.
exit -1
