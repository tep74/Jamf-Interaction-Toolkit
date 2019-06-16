#!/bin/bash
# set -x 
##########################################################################################
##						Get The Jamf Interaction Configuration 							##
##########################################################################################

fn_read_uex_Preference () {
	local domain="$1"
	defaults read /Library/Preferences/github.cubandave.uex.plist "$domain"
}

UEXFolderPath="$(fn_read_uex_Preference "UEXFolderPath")"
# in case the plist hasn't been create on this version then set it to the previous standard
if [[ -z "$UEXFolderPath" ]] ; then
	UEXFolderPath="/Library/Application Support/JAMF/UEX"
fi

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
# cubandave(https://github.com/cubandave)
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
logdir="$UEXFolderPath/UEX_Logs/"
compname=`scutil --get ComputerName`
# resulttmp="$logname"_result.log
##########################################################################################

jamfBinary="/usr/local/jamf/bin/jamf"

##########################################################################################
# 										Functions										 #
##########################################################################################

fn_getPlistValue () {
	/usr/libexec/PlistBuddy -c "print $1" "$UEXFolderPath"/$2/"$3"
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
	# only put in the log if it exist
	if [[ "$logfilepath" ]] ; then
		echo $(date)	$compname	:	"$1"  | tee -a "$logfilepath"
	else
		echo $(date)	$compname	:	"$1"
	fi
}


triggerNgo ()
{
	$jamfBinary policy -forceNoRecon -trigger $1 &
}

##########################################################################################
##					PROCESS PLISTS AND RESTARTING INSTALLS IF READY						##
##########################################################################################

loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root`
logoutHookRunning=`ps aux | grep "JAMF/ManagementFrameworkScripts/logouthook.sh" | grep -v grep`

if [ "$logoutHookRunning" ] ; then 
	loggedInUser=""
fi

plists=`ls "$UEXFolderPath"/defer_jss/ | grep ".plist"`
runDate=`date +%s`

IFS=$'\n'
for i in $plists ; do
	policyTriggerResult=""
	BatteryTest=`pmset -g batt`
	loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root`
	logoutHookRunning=`ps aux | grep "JAMF/ManagementFrameworkScripts/logouthook.sh" | grep -v grep`

	if [ "$logoutHookRunning" ] ; then 
		loggedInUser=""
	fi
	
	# Process the plist	
	delayDate=$(fn_getPlistValue "delayDate" "defer_jss" "$i")
	packageName=$(fn_getPlistValue "package" "defer_jss" "$i")
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
			log4_JSS "$jamfBinary policy -trigger $policyTrigger"
			policyTriggerResult=`$jamfBinary policy -trigger "$policyTrigger"`
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
		log4_JSS "Running: $jamfBinary policy -trigger $policyTrigger"
		policyTriggerResult=`$jamfBinary policy -trigger "$policyTrigger"`
	fi

	# plist clean up if no policy found
	# if [[ "$policyTriggerResult" == *"No policies were found for the \"$policyTrigger\" trigger."* ]] && [[ "$policyTriggerResult" != *"Could not connect to the JSS"* ]] ; then
	if [[ "$policyTriggerResult" == *"No policies were found for the \"$policyTrigger\" trigger."* ]] ; then
		log4_JSS "No policy found for: $policyTrigger"
		log4_JSS "Deleting $i"
		/bin/rm "$UEXFolderPath/defer_jss/$i"
	fi
	
done
unset IFS

# if the defer folder is now empty then you should do an inventory update to stop deferral service from running
deferfolderContents=`ls "$UEXFolderPath/defer_jss/" | grep plist`
if [[ -z "$deferfolderContents" ]]; then
	log4_JSS "No more deferrals."
	InventoryUpdateRequired=true
fi

if [[ "$InventoryUpdateRequired" = true ]] ;then 
	log4_JSS "Inventory Update Required"
	triggerNgo uex_inventory_update_agent
fi

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
# Apr 24, 2018 	v3.7	--cubandave--	Functions added
# Oct 24, 2018 	v4.0	--cubandave--	All Change logs are available now in the release notes on GITHUB
# 
