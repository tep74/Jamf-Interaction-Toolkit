#!/bin/bash

jamfBinary="/usr/local/jamf/bin/jamf"

##########################################################################################
##########################################################################################
# 
# This can be used for UEX and non-UEX Policies to trigger the install policy.
# 
# Version Number: 4.2
# 
# Created January 31st, 2017 by
# cubandave (https://github.com/cubandave) 
# 
# Updates found on github
# https://github.com/cubandave/Jamf-Interaction-Toolkit/commits/master
# 
# cubandave/Jamf-Interaction-Toolkit is licensed under the
# Apache License 2.0
# https://github.com/cubandave/Jamf-Interaction-Toolkit/blob/master/LICENSE
##########################################################################################
########################################################################################## 

triggers="$4"

IFS=";"
set -- "$triggers"
##This works because i'm setting the seperator
# shellcheck disable=SC2048
declare -a triggers=($*)
unset IFS



for triggerName in "${triggers[@]}" ; do

	"$jamfBinary" policy -forceNoRecon -trigger "$triggerName"

	if [[ $? != 0 ]] ; then
		echo The policy for trigger "$triggerName" exited in a non-zero status
		failedInstall=true
	fi
done


if [ "$failedInstall" = true ] ; then 
	exit 1
else
	exit 0
fi



##########################################################################################
##									Version History										##
##########################################################################################
# 
# 
# Jan 31, 2017 	v1.0	--cubandave--	Version 1 Created
# Sep 11, 2017 	v2.0	--cubandave--	Added checking for status of installation
# Sep 26, 2017 	v3.2	--cubandave--	Added Support for multiple trigger names seperated by ;
# Oct 24, 2018 	v4.0	--cubandave--	All Change logs are available now in the release notes on GITHUB
#