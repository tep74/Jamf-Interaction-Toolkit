#!/bin/bash

# used for major debugging
# set -x

loggedInUser=$( /bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root )

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

customLogo="$(fn_read_uex_Preference "customLogo")"

SelfServiceIcon="$(fn_read_uex_Preference "SelfServiceIcon")"

##########################################################################################
##########################################################################################
##							DO NOT MAKE ANY CHANGES BELOW								##
##########################################################################################
##########################################################################################
# 
# Block script runs through plists in ../UEX/block_jss/ to kill apps during installation. 
# It run through the list of apps checks to see if they are running and then kills them.
# 
# Name: Block-notification.sh
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
##						STATIC VARIABLES FOR CocoaDialog DIALOGS						##
##########################################################################################

CocoaDialog="$UEXFolderPath/resources/cocoaDialog.app/Contents/MacOS/CocoaDialog"

##########################################################################################


##########################################################################################
##							STATIC VARIABLES FOR DIALOGS								##
##########################################################################################

#if the icon file doesn't exist then set to a standard icon
if [[ -e "$SelfServiceIcon" ]] ; then
	icon="$SelfServiceIcon"
elif [ -e "$customLogo" ] ; then
	icon="$customLogo"
else
	icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
fi

##########################################################################################

##########################################################################################
# 										LOGGING PREP									 #
##########################################################################################
# logname="${packageName##*/}"
# logfilename="$logname".log
logdir="$UEXFolderPath/UEX_Logs/"
compname=$( scutil --get ComputerName )
##########################################################################################

##########################################################################################
# 										Functions										 #
##########################################################################################

fn_getPlistValue () {
	/usr/libexec/PlistBuddy -c "print $1" "$UEXFolderPath/$2/$3"
}

logInUEX () {
	echo "$(date)"	"$compname"	:	"$1" >> "$logfilepath"
}

logInUEX4DebugMode () {
	if [[ "$debug" = true ]] ; then	
		logMessage="-DEBUG- $1"
		logInUEX "$logMessage"
	fi
}

log4_JSS () {
	echo "$(date)"	"$compname"	:	"$1"  | tee -a "$logfilepath"
}

##################################
# 		Creating Arrays			 #
##################################	

IFS=$'\n'
blockPlists=($( ls "$UEXFolderPath"/block_jss/ | grep ".plist" ))
unset IFS

##################################
# 		FOR PLIST CLEANUP		 #
##################################	

lastReboot=$( date -jf "%s" "$(sysctl kern.boottime | awk -F'[= |,]' '{print $6}')" "+%s" )

##################################
# 		PLIST PROCESSING		 #
##################################

runBlocking=$( ls "$UEXFolderPath"/block_jss/ | grep ".plist" )
	while [ "$runBlocking" ] ; do
	
	runBlocking=$( ls "$UEXFolderPath"/block_jss/ | grep ".plist" )
	
	IFS=$'\n'
	blockPlists=($( ls "$UEXFolderPath"/block_jss/ | grep ".plist" ))
	unset IFS
	
	for i in "${blockPlists[@]}" ; do
		# Run through the plists and check for app blocking requirements
		packageName=$(fn_getPlistValue "packageName" "block_jss" "$i")
		apps=$(fn_getPlistValue "apps2block" "block_jss" "$i")
		checks=$(fn_getPlistValue "checks" "block_jss" "$i"	)
		runDate=$(fn_getPlistValue "runDate" "block_jss" "$i")

		# runDateFriendly=$( date -r$runDate )
		timeSinceReboot=$((lastReboot-runDate))
		
		##########################################################################################
		##									SETTING FOR ACTIONS									##
		##########################################################################################
		if [[ "$checks" == *"install"* ]] && [[ "$checks" != *"uninstall"* ]] ; then
			action="install"
			actioncap="Install"
		elif [[ "$checks" == *"update"* ]] ; then
			action="update"
			actioncap="Update"
		elif [[ "$checks" == *"uninstall"* ]] ; then
			action="uninstall"
			actioncap="Uninstall"
		else
			action="install"
			actioncap="Install"
		fi
	
		##########################################################################################
		##									SETTING FOR DEBUG MODE								##
		##########################################################################################

		debugDIR="$UEXFolderPath/debug/"

		if [ -e "$debugDIR""$packageName" ] ; then 
			debug=true
		else
			debug=false
		fi
	
		##########################################################################################
	
	
		#######################
		# Logging files setup #
		#######################
		logname="${packageName##*/}"
		logfilename="$logname".log
		logfilepath="$logdir""$logfilename"
	
		# Create array of apps to run through checks
		set -- "$apps"
		IFS=";"
		##This works because i'm setting the seperator
		# shellcheck disable=SC2048
		declare -a apps=($*)  
		unset IFS

		if [[ timeSinceReboot -gt 0 ]] ; then
			# the computer has rebooted since $runDateFriendly
			# Delete block requirement plist
			rm "$UEXFolderPath"/block_jss/"$i"
		else 
			# the computer has NOT rebooted since $runDateFriendly
			# Process the apps in the plist and kill and notify
			for app in "${apps[@]}" ; do
				IFS=$'\n'
				
				## This is needed to get the parent proccess and prevent unwanted blocking
				# shellcheck disable=SC2009
				id=$( ps aux | grep "$app"/Contents/MacOS/ | grep -v grep | grep -v PleaseWaitUpdater.sh | grep -v PleaseWait | grep -v sed | grep -v jamf | grep -v cocoaDialog | awk '{ print $2 }' )
	# 			echo Processing application $app
					if  [[ $id != "" ]] ; then
						# app was running so kill it then give the notification
					
						################################
						# Debugging applications kills #
						################################
						
						## This is needed to get the parent proccess and prevent unwanted blocking
						# shellcheck disable=SC2009
						processData=$( ps aux | grep "$app"/Contents/MacOS/ | grep -v grep | grep -v PleaseWaitUpdater.sh | grep -v PleaseWait | grep -v sed | grep -v jamf | grep -v cocoaDialog  )
						for process in $processData ; do
							if [[ "$debug" = true ]] ; then	echo "$(date)"	"$compname"	:	-DEBUG-	 '*****' PROCESSS FOUND MATCHING CRITERIA '******' | /usr/bin/tee -a "$logfilepath" ; fi
							if [[ "$debug" = true ]] ; then	echo "$(date)"	"$compname"	:	-DEBUG-	 "$process" | /usr/bin/tee -a "$logfilepath" ; fi
						done
						####################################
						# Debugging applications kills END #
						####################################
					
						if [[ "$checks" == *"merp"* ]] ; then
							log4_JSS "Trying to safe quit $app to avoid Microsoft Error Reporting"
							sudo -u "$loggedInUser" -H osascript -e "activate app \"$app\""
							sudo -u "$loggedInUser" -H osascript -e "quit app \"$app\""
							sleep 2
						fi
							
						processstatus=$( ps -p "$id" )
						if [[ "$processstatus" == *"$app"* ]] ; then
							log4_JSS "$app is still running. Killing process id $id."
							kill "$id"
							sleep 1
						fi

						processstatus=$( ps -p "$id" )
						if [[ "$processstatus" == *"$app"* ]] ; then
							#statements
							log4_JSS "The process $id was still running for application $app. Force killing Application."
							kill -9 "$id"
						fi 
#################
# MESSAGE START #
#################
appName="${app//.app/}"

# Use cocoaDialog so that it appears in front 
"$CocoaDialog" bubble \
--title "$actioncap in progress..." --x-placement center --y-placement center \
--text "The application ${appName} cannot be opened while the $action is still in progress.

Please wait for it to complete before attempting to open it." \
	--icon-file "$icon" --icon-size 64 --independent --timeout 30


###############
# MESSAGE END #
###############
	
					fi
				done
				unset IFS	
		fi
	done
done

##########################################################################################
exit 0

##########################################################################################
##									Version History										##
##########################################################################################
# 
# 
# Jan 18, 2016 	v1.0	--cubandave--	Stage 1 Delivered
# Sep 1, 2016 	v2.0	--cubandave--	Logging added
# Sep 1, 2016 	v2.0	--cubandave--	Debug mode added
# Sep 7, 2016 	v2.0	--cubandave--	Updated to clean up Application quitting and only target process from /$app/Contents/MacOS/
# Apr 24, 2018 	v3.7	--cubandave--	Funtctions added
# Oct 24, 2018 	v4.0	--cubandave--	All Change logs are available now in the release notes on GITHUB
# 
