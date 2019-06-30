#!/bin/bash

# used for major debugging
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
# 
# Runs While PleaseWait.app is running to cycle though prohibited apps and required
# restarts and logouts
# 
# Name: PleaseWaitUpdater.sh
# Version Number: 4.2
# 
# Created Jan 18, 2016 by 
# cubandave(https://github.com/cubandave)
# 
# 
# cubandave/Jamf-Interaction-Toolkit is licensed under the
# Apache License 2.0
# https://github.com/cubandave/Jamf-Interaction-Toolkit/blob/master/LICENSE
##########################################################################################
########################################################################################## 


# PleaseWaitApp="$UEXFolderPath/resources/PleaseWait.app"
pleasewaitPhase="/private/tmp/com.pleasewait.phase"
pleasewaitProgress="/private/tmp/com.pleasewait.progress"
# pleasewaitInstallProgress="/private/tmp/com.pleasewait.installprogress"

##########################################################################################
# 									Functions											 #
##########################################################################################

fn_getPlistValue () {
	/usr/libexec/PlistBuddy -c "print $1" "$2"
}


##########################################################################################
# 									Script Start										 #
##########################################################################################

sleep 10

# while PleaseWait.app is running 
while [ ! -z "$( pgrep PleaseWait )" ] ; do 

IFS=$'\n'
# Get a list of plist from the UEX folder
plists=($( find "/Library/Application Support/JAMF/UEX" -name '*.plist' | grep -v resources ))
unset IFS

# set -- "$plists" 
# IFS=$'\n'
# ##This works because i'm setting the seperator
# # shellcheck disable=SC2048
# declare -a plists=($*)
# unset IFS

installjss="$UEXFolderPath/install_jss/"

#Cycle through list of plists
	for plist in "${plists[@]}" ; do
		
		# if there is a place holder for an install in progress
		if [[ "$plist" == *"UEX/install"* ]] ;then		

			name=$(fn_getPlistValue "name" "$plist")
			checks=$(fn_getPlistValue "checks" "$plist")

			if [[ "$checks" == *"install"* ]] && [[ "$checks" != *"uninstall"* ]] ; then
				action="install"
				actioncap="Install"
				actioning="installing"
			elif [[ "$checks" == *"update"* ]] ; then
				action="update"
				actioncap="Update"
				actioning="updating"
			elif [[ "$checks" == *"uninstall"* ]] ; then
				action="uninstall"
				actioncap="Uninstall"
				actioning="uninstalling"
			else
				action="install"
				actioncap="Install"
				actioning="installing"
			fi
			
			if [[ "$checks" == *"install"* ]] ; then
				echo "Software updates in progress" > $pleasewaitPhase
				echo "Please do not turn off your computer." > $pleasewaitProgress
			else
				echo "$actioncap in progress..." > $pleasewaitPhase
				echo "Now $actioning" "$name" > $pleasewaitProgress
			fi
			
			
			sleep 5
		fi
	
		# if the plist is a block plist then notify the user that the apps can't be opened 
		if [[ "$plist" == *"UEX/block"* ]] ;then
			apps=$(fn_getPlistValue "apps2block" "$plist")

			# Create array of apps to run through checks
			set -- "$apps" 
			IFS=";"
			##This works because i'm setting the seperator
			# shellcheck disable=SC2048
			declare -a apps=($*)  
			unset IFS
			# Cycle through list of prohibited apps from the block plist config file
			for app in "${apps[@]}" ; do
				echo "Please do not open these applications" > $pleasewaitPhase
				echo "${app//.app/}" > $pleasewaitProgress
				sleep 3
			done
		
			sleep 2	
		
		sleep 10
		fi
	
	# 	if there are logout plist present then notify that a logout will be required
		if [[ "$plist" == *"UEX/logout"* ]] ;then
			plistName="${plist##*/}"
			if [ -e "$installjss""$plistName" ] ; then
				echo "A logout will be required..." > $pleasewaitPhase
				echo "after $action completes." > $pleasewaitProgress
				sleep 5
			fi
		fi
	
	# 	if there are restart plist present then notify that a restart will be required
		if [[ "$plist" == *"UEX/restart"* ]] ;then
			plistName="${plist##*/}"
			if [ -e "$installjss""$plistName" ] ; then
				echo "A restart will be required..." > $pleasewaitPhase
				echo "after $action completes." > $pleasewaitProgress
				sleep 5
			fi
		fi
	done

done


##########################################################################################
##									Version History										##
##########################################################################################
# 
# 
# Jan 18, 2016 	v1.0	--cubandave--	Stage 1 Delivered
# Apr 24, 2018 	v3.7	--cubandave--	Funtctions added
# Oct 24, 2018 	v4.0	--cubandave--	All Change logs are available now in the release notes on GITHUB
#