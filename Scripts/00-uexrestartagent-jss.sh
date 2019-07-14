#!/bin/bash

# used for major debugging
# set -x

loggedInUser=$( /bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root )

##########################################################################################
##						Manual Jamf Interaction Configuration 							##
##########################################################################################

enable_filevault_reboot=false


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

title="$(fn_read_uex_Preference "title")"

customLogo="$(fn_read_uex_Preference "customLogo")"

SelfServiceIcon="$(fn_read_uex_Preference "SelfServiceIcon")"


##########################################################################################
##########################################################################################
##							DO NOT MAKE ANY CHANGES BELOW								##
##########################################################################################
##########################################################################################
# 
# Restart notification checks the plists in the ../UEX/logout2.0/ folder to notify & force a
# restart if required.
# 
# Name: restart-notification.sh
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
##							STATIC VARIABLES FOR JH DIALOGS								##
##########################################################################################

jhPath="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

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
# resulttmp="$logname"_result.log
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

fn_getPassword () {
	"$CocoaDialog" standard-inputbox --no-show --title "$title" --informative-text "Please enter in your password" -no-newline --icon-file "$icon" | tail +2
}

log4_JSS () {
	echo "$(date)"	"$compname"	:	"$1"  | tee -a "$logfilepath"
}

##########################################################################################
##			CALCULATIONS TO SEE IF A RESTART HAS OCCURRED SINCE BEING REQUIRED			##
##########################################################################################

lastReboot=$( date -jf "%s" "$(sysctl kern.boottime | awk -F'[= |,]' '{print $6}')" "+%s" )
lastRebootFriendly=$( date -r "$lastReboot" )

# runDate=$( date +%s )

IFS=$'\n'
## Need the plist as a file name in list format
# shellcheck disable=SC2010
plists=( "$( ls "$UEXFolderPath"/restart_jss/| grep ".plist" )" )
unset IFS

# plists=$( ls "$UEXFolderPath"/restart_jss/ | grep ".plist" )

# set -- "$plists" 
# ##This works because i'm setting the seperator
# # shellcheck disable=SC2048
# IFS=$'\n' ; declare -a plists=($*)  
# unset IFS

for i in "${plists[@]}" ; do
	# Check all the plist in the folder for any required actions
	# if the user has already had a fresh restart then delete the plist
	# other wise the advise and schedule the logout.
	
	# name=$(fn_getPlistValue "name" "restart_jss" "$i")
	packageName=$(fn_getPlistValue "packageName" "restart_jss" "$i")
	plistrunDate=$(fn_getPlistValue "runDate" "restart_jss" "$i")
	# runDateFriendly=$( date -r $plistrunDate )
	
# 	echo lastReboot is $lastReboot
# 	echo plistRunDate is $plistRunDate
	
	timeSinceReboot=$( echo "${lastReboot} - ${plistrunDate}" | bc )
	
	#######################
	# Logging files setup #
	#######################
	logname="${packageName##*/}"
	logfilename="$logname".log
	# resulttmp="$logname"_result.log
	logfilepath="$logdir""$logfilename"
	
# 	echo timeSinceReboot is $timeSinceReboot
	if [[ $timeSinceReboot -gt 0 ]] || [ -z "$plistrunDate" ]  ; then
		# the computer has rebooted since $runDateFriendly
		#delete the plist
		logInUEX "Deleting the restart plsit $i because the computer has rebooted since $lastRebootFriendly"
		rm "$UEXFolderPath/restart_jss/$i"
	else 
		# the computer has NOT rebooted since $runDateFriendly
		lastline=$( awk 'END{print}' "$logfilepath" )
		if [[ "$lastline" != *"Prompting the user"* ]] ; then 
			logInUEX "The computer has NOT rebooted since $lastRebootFriendly"
			logInUEX "Prompting the user that a restart is required"
		fi
		restart="true"
	fi
done

##########################################################################################

##########################################################################################
## 							Login Check Run if no on is logged in						##
##########################################################################################
# no login  RUN NOW
# (skip to install stage)
loggedInUser=$( /bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root )

##########################################################################################
##					Notification if there are scheduled restarts						##
##########################################################################################

osMajor=$( /usr/bin/sw_vers -productVersion | awk -F. '{print $2}' )

sleep 15
## This is needed to rule out only what's needed
# shellcheck disable=SC2009
otherJamfprocess=$( ps aux | grep jamf | grep -v grep | grep -v launchDaemon | grep -v jamfAgent | grep -v uexrestartagent )
otherJamfprocess+=$( pgrep SplashBuddy )
if [[ "$restart" == "true" ]] ; then
	while [[ $otherJamfprocess != "" ]] ; do 
		sleep 15
		## This is needed to rule out only what's needed
		# shellcheck disable=SC2009
		otherJamfprocess=$( ps aux | grep jamf | grep -v grep | grep -v launchDaemon | grep -v jamfAgent | grep -v uexrestartagent )
		otherJamfprocess+=$( pgrep SplashBuddy )
	done
fi

# only run the restart command once all other jamf policies have completed
if [[ $otherJamfprocess == "" ]] ; then 
	if [[ "$restart" == "true" ]] ; then


##########################################################################################
##						FileVault Authenticated reboot									##
##########################################################################################

		fvUsers=("$(fdesetup list | awk -F',' '{ print $1}')")
		fvAutrestartSupported=$( fdesetup supportsauthrestart )
		fvStatus="$( fdesetup status | tr '[:upper:]' '[:lower:]' )"

		for user2Check in "${fvUsers[@]}"; do
			# Check if the logged in user can unlock the disk by lopping through the user that are able to unlock it

			if [[ "$loggedInUser" == "$user2Check" ]] ; then
				# set the unlock disk variable so that the user can be prompted if they want to do an authenticated restart
				userCanUnLockDisk=true
				break
			fi
		done

		# only if some one is logged in and can unlock the disk and it's supported
		## Only if FV is on too because #60
		if [[ $loggedInUser ]] && [[ "$userCanUnLockDisk" = true ]] && [[ "$fvAutrestartSupported" = true ]] && [[ "$enable_filevault_reboot" = true ]] && [[ "$fvStatus" == *"on"* ]] ; then
	
			fvUnlockHeading="FileVault Authorized Restart"
			fvUnlockNotice='In order for the changes to complete you must restart your computer. Please save your work. 
	
Would you to like enter your password to have the computer unlock the disk automatically? 
Note: Automatic unlock does not always occur.'
	
		#notice
		fvUnlockButton=$( "$jhPath" -windowType hud -lockHUD -heading "$fvUnlockHeading" -windowPostion lr -title "$title" -description "$fvUnlockNotice" -icon "$icon" -timeout 300 -countdown -alignCountdown center -button1 "No" -button2 "Yes"  )
		
			if [[ "$fvUnlockButton" = 2 ]] ; then
				log4_JSS "User chose to restart with an authenticatedRestart"
				authenticatedRestart=true
				passwordLooper=0
				while [[ "$passwordLooper" = 0 ]]; do
					#statements
					userPassword=""
					userPassword="$(fn_getPassword)"

				if [[ "$userPassword" ]] ; then
					#statements
					authenticatedRestart=true
					expect -c "
					log_user 0
					spawn fdesetup authrestart
					expect \"Enter the user name:\"
					send {${loggedInUser}}
					send \r
					expect \"Enter the password for user '{${loggedInUser}}':\"
					send {${userPassword}}
					send \r
					log_user 1
					expect eof
					"
				fi # if there is a userPassword entered

				fvUnlockErrorNotice='There was error with the authorized restart. Your password may be incorrect, out of sync, or blank.

	Click "Try Again" or "Cancel".'
		
				#notice
				fvUnlockErrorButton=$( "$jhPath" -windowType hud -lockHUD -heading "$fvUnlockHeading" -windowPostion lr -title "$title" -description "$fvUnlockErrorNotice" -icon "$icon" -timeout 300 -countdown -alignCountdown center -button1 "Cancel" -button2 "Try Again"  )
				if [[ "$fvUnlockErrorButton" = 2 ]] ; then
					#statements
					passwordLooper=0
				else
					authenticatedRestart=false
					passwordLooper=1
				fi # user chose to try again

				done 

			fi # if the user chose to try an authenticated restart

		fi # if user can unlock a disk supporting authenticated restart

##########################################################################################
##									Standard reboot										##
##########################################################################################
		
		if [[ "$loggedInUser" ]] && [[ "$authenticatedRestart" != true ]] ; then
		# message
		notice='In order for the changes to complete you must restart your computer. Please save your work and click "Restart Now" within the allotted time. 
	
Your computer will be automatically restarted at the end of the countdown.'
	
		#notice
		"$jhPath" -windowType hud -lockHUD -windowPostion lr -title "$title" -description "$notice" -icon "$icon" -timeout 3600 -countdown -alignCountdown center -button1 "Restart Now"
	
			if [[ "$authenticatedRestart" = true ]] ;then
				log4_JSS "ENTRY 2: User chose to restart with an authenticatedRestart"

			elif [[ "$osMajor" -ge 14 ]] ; then
				#statements
				shutdown -r now
			else
				# Nicer restart (http://apple.stackexchange.com/questions/103571/using-the-terminal-command-to-shutdown-restart-and-sleep-my-mac)
				osascript -e 'tell app "System Events" to restart'
			fi # OS is ge 14

		else # no one is logged in
			# force restart
			# while no on eis logged in you can do a force shutdown

			logInUEX "no one is logged in forcing a restart."
			shutdown -r now
			# Nicer restart (http://apple.stackexchange.com/questions/103571/using-the-terminal-command-to-shutdown-restart-and-sleep-my-mac)
# 			osascript -e 'tell app "System Events" to restart'
		fi
	fi
fi

##########################################################################################

exit 0

##########################################################################################
##									Version History										##
##########################################################################################
# 
# 
# Jan 18, 2016 	v1.0	--cubandave--	Stage 1 Delivered
# Sep 5, 2016 	v2.0	--cubandave--	Logging added
# Apr 24, 2018 	v3.7	--cubandave--	Funtctions added
# Oct 24, 2018 	v4.0	--cubandave--	All Change logs are available now in the release notes on GITHUB
# 
