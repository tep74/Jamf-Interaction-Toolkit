#!/bin/bash

##########################################################################################
##########################################################################################
# 
# Run Deferred checks the plists in ../UEX/defer_jss/ folder for any installs that any
# PKGs that have been deferred once enough time has elapsed OR if no one is logged in.
# 
# Name: deferral-service
# Version Number: 4.2
# 
# Created Jan 18, 2016 by 
# David Ramirez (https://github.com/cubandave)
#
# Updates found on github
# https://github.com/cubandave/Jamf-Interaction-Toolkit/commits/master
# 
# cubandave/Jamf-Interaction-Toolkit is licensed under the
# Apache License 2.0
# https://github.com/cubandave/Jamf-Interaction-Toolkit/blob/master/LICENSE
##########################################################################################
########################################################################################## 

##########################################################################################
# 										LOGGING PREP									 #
##########################################################################################
# logname=$(echo $packageName | sed 's/.\{4\}$//')
# logfilename="$logname".log
logdir="/Library/Application Support/JAMF/UEX/UEX_Logs/"
# resulttmp="$logname"_result.log
##########################################################################################


##########################################################################################
# 										Functions										 #
##########################################################################################

fn_getPlistValue () {
	/usr/libexec/PlistBuddy -c "print $1" /Library/Application\ Support/JAMF/UEX/$2/"$3"
}

logInUEX () {
	echo $(date)	$compname	:	"$1" >> "$logfilepath"
}

logInUEX4DebugMode () {
	if [ $debug = true ] ; then	
		logMessage="-DEBUG- $1"
		logInUEX $logMessage
	fi
}

log4_JSS () {
	echo $(date)	$compname	:	"$1"  | tee -a "$logfilepath"
}

##########################################################################################
##					PROCESS PLISTS AND RESTARTING INSTALLS IF READY						##
##########################################################################################

loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root`
logoutHookRunning=`ps aux | grep "JAMF/ManagementFrameworkScripts/logouthook.sh" | grep -v grep`

if [ "$logoutHookRunning" ] ; then 
	loggedInUser=""
fi

plists=`ls /Library/Application\ Support/JAMF/UEX/defer_jss/ | grep ".plist"`
runDate=`date +%s`

IFS=$'\n'
for i in $plists ; do
	BatteryTest=`pmset -g batt`
	loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root`
	logoutHookRunning=`ps aux | grep "JAMF/ManagementFrameworkScripts/logouthook.sh" | grep -v grep`

	if [ "$logoutHookRunning" ] ; then 
		loggedInUser=""
	fi
	
	# Process the plist	
	delayDate=$(fn_getPlistValue "delayDate" "defer_jss" "$i")
	packagename=$(fn_getPlistValue "package" "defer_jss" "$i")
	folder=$(fn_getPlistValue "folder" "defer_jss" "$i")
	loginscreeninstall=$(fn_getPlistValue "loginscreeninstall" "defer_jss" "$i")
	checks=$(fn_getPlistValue "checks" "defer_jss" "$i")
	policyTrigger=$(fn_getPlistValue "policyTrigger" "defer_jss" "$i")

	#######################
	# Logging files setup #
	#######################
	logname=$(echo $packageName | sed 's/.\{4\}$//')
	logfilename="$logname".log
	resulttmp="$logname"_result.log
	logfilepath="$logdir""$logfilename"
	resultlogfilepath="$logdir""$resulttmp"
	
	# calculate the time elapsed
	timeelapsed=$((delayDate-runDate))
	skip=""
	if [ $loggedInUser ] ; then
		# string contains a user ID therefore someone is logged in
		if [ "$timeelapsed" -lt 0 ] ; then
		# Enough time has passed 
		# start the install
			log4_JSS "Enough time has passed starting the install"
			/usr/local/bin/jamf policy -trigger "$policyTrigger"
		fi
	elif [[ $loggedInUser == "" ]] && [[ $loginscreeninstall == false ]] ; then
		# skipping install
		skip=true
	elif [[ $loggedInUser == "" ]] && [[ $loginscreeninstall == true ]] && [[ $checks == *"power"* ]] && [[ "$BatteryTest" != *"AC"* ]] ; then
		# skipping install
		skip=true
	else 
	# loggedInUser is null therefore no one is logged in
	# start the install
		logInUEX "No one is logged"
		logInUEX "Login screen install permitted"
		logInUEX "All requrements met"
		logInUEX "Starting Install"

		killall loginwindow
		/usr/local/bin/jamf policy -trigger "$policyTrigger"
	fi
	
done
unset IFS

##########################################################################################
exit 0

##########################################################################################
##									Version History										##
##########################################################################################
# 
# 
# Jan 18, 2016 	v1.0	--cubandave--	Stage 1 Delivered
# May 22, 2016 	v1.3	--cubandave--	added considerations for loginscreeninstall (power reqs & time etc.)
# Sep 5, 2016 	v2.0	--cubandave--	Logging added
# Sep 5, 2016 	v2.0	--cubandave--	Debug mode added
# Apr 24, 2018 	v3.7	--cubandave--	Funtctions added
# Oct 24, 2018 	v4.0	--cubandave--	All Change logs are available now in the release notes on GITHUB
# 
