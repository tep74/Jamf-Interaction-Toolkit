#!/bin/bash

# used for major debugging
# set -x
loggedInUser=$( /bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root )
loggedInUserHome=$( dscl . read "/Users/$loggedInUser" NFSHomeDirectory | awk '{ print $2 }' )

##Saving this for later
# CONSOLE=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')

##########################################################################################
##								Jamf Interaction Configuration 							##
##########################################################################################

UEXFolderPath="/Library/Application Support/JAMF/UEX"

title="Your IT Department"

# Jamf Pro 10 icon if you want another custom one then please update it here.
# or you can customize this with an image you've included in UEX resources or is already local on the computer
customLogo="/Library/Application Support/JAMF/Jamf.app/Contents/Resources/AppIcon.icns"

# if you you jamf Pro 10 to brand the image with your self sevice icon will be here
# or you can customize this with an image you've included in UEX resources or is already local on the computer
SelfServiceIcon="$loggedInUserHome/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"

# if you want to customize the icon users see when they have insufficient space you can specif the path
# if you include it in your UEX resources it will install there 
diskicon="/System/Library/Extensions/IOStorageFamily.kext/Contents/Resources/Internal.icns"

# use this to customize the name of your IT Support team when space notification tickets are created 
ServiceDeskName="IT Support"

# Use this to customize the name of your jamf admin team signature in the compliance notification
jamfOpsTeamName="System Administrator"

# This enables the interaction for Help Disk Tickets
# by default it is disabled. For more info on how to use this check the wiki in the Help Desk Ticket Section
helpTicketsEnabled=false
helpTicketsEnabledViaAppRestriction=false
helpTicketsEnabledViaTrigger=false
helpTicketsEnabledViaFunction=false

# If you move the UEX Resources to another location or use a difffernt app then change this.
restrictedAppName="$UEXFolderPath/resources/User Needs Helps Clearing Space.app"

# Change this to your own trigger if you want to use a custom policy to notify you
# NOTE if you make it blank then it assumes you're creating a policy for each UEX policy using  
# the below naming convention
# EXAMPLE: "$UEXpolicyTrigger""_helpticket"
# EXAMPLE REmoval Policy: "$UEXpolicyTrigger""_helpticket"
UEXhelpticketTrigger="add_to_group_for_disk_space_help_ticket"
ClearHelpTicketRequirementTrigger="remove_from_group_for_disk_space_help_ticket"


# NEW SOFTWARE UPDTATE OPTIONS
# use this to run a trigger to set your software update server via a policy 
# Highly Recomend using Configuration Profiles though.
# For a handy script to use API to calculate the SUS server check out:
# https://github.com/patchoo/patchoo/blob/master/extras/asucatalogset.sh
susSetByTrigger=false
susSettingTriggerName="set_sus_server"




##########################################################################################
##						Create help Desk Ticket Via Function 							##
##########################################################################################
# feel free to do what ever the heck you want here.
# if you have API to create ticket with your Incident Managment System
# GO NUTS
fn_create_help_desk_ticket () {

	sleep 1
	echo "I'm not doing anything yet...;-p. Plz update fn_create_help_desk_ticket"
	echo "or turn off helpTicketsEnabledViaFunction"

}

##########################################################################################
##########################################################################################
##							DO NOT MAKE ANY CHANGES BELOW								##
##########################################################################################
##########################################################################################
jhPath="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
# 
# User experience Post installation script to be bundled with PKG.
# 
# Version Number: 4.2
	uexvers=4.2
# 
# Created: January 23rd, 2017 by
# cubandave(https://github.com/cubandave)
# 
# Updates found on github
# https://github.com/cubandave/Jamf-Interaction-Toolkit/commits/master
# 
# 
# cubandave/Jamf-Interaction-Toolkit is licensed under the
# Apache License 2.0
# https://github.com/cubandave/Jamf-Interaction-Toolkit/blob/master/LICENSE
##########################################################################################
########################################################################################## 

##########################################################################################
# 						Write Jamf Interaction Configuration to Plist 					 #
##########################################################################################

fn_write_uex_Preference () {
	local domain="$1"
	local key="$2"
	defaults write /Library/Preferences/github.cubandave.uex.plist "$domain" "$key" 
}

fn_write_uex_Preference "UEXFolderPath" "$UEXFolderPath"

fn_write_uex_Preference "title" "$title"

fn_write_uex_Preference "customLogo" "$customLogo"

fn_write_uex_Preference "SelfServiceIcon" "$SelfServiceIcon"



##########################################################################################
jamfBinary="/usr/local/jamf/bin/jamf"
osMajor=$( /usr/bin/sw_vers -productVersion | awk -F. '{print $2}' )

##########################################################################################
##									Paramaters for UEX									##
##########################################################################################

# NameConsolidated="AppVendor;AppName;AppVersion;Space Req'd in GB"
# LABEL: NameConsolidated
NameConsolidated=$4

# options 1 of the following (quit,block,restart,logout)
# can also be (quit restart) or (quit logout)
# can also be (block restart) or (block logout)
# NEW individual checks (macosupgrade) (saveallwork)
# Coming soon (lock) (loginwindow)
# aditional options (power) (nopreclose)
# if the install is critical add "critical"
# if the app is available in Self Service add "ssavail"
# LABEL: Checks
checks=$( echo "$5" | tr '[:upper:]' '[:lower:]' )


# apps="xyz.app;asdf.app"
# LABEL: Apps for Quick and Block
apps=$6

# Theres are alternate paths that the applications
# if the path is the user folder then use the ~/ sign
##Needed to indicate home folders
# shellcheck disable=SC2088
altpaths=(
"/Users/Shared/"
"/Library/Application Support/"
"~/Library/Application Support/"
)

# Timed installation on a HDD based Mac
# installDuration=5
# LABEL: InInstallDuration - Must be integer
installDuration=$7

# default is 1
# maxdefer="1"
# LABEL: "Maximum Deferral of Postponements;Service Desk Disk Space Limit - Must be integer"
maxdeferConsolidated="$8"

# Insert name of PKG files here that are copying to /private/tmp/ during install
# Must be in the format of the example to execute properly
# Will install in sequential order that is listed
# LABEL: Package fileNames
# packages=(install.pkg;install2.pkg)
packages=$9


triggers=${10}


customMessage=${11}


# for debugging
# NameConsolidated="UEX;restart tests Dialog;1.0"
# checks=$( echo "macosupgrade saveallwork power" | tr '[:upper:]' '[:lower:]' )
# apps=""
# installDuration=15
# maxdeferConsolidated="1"
# packages=""
# triggers="msupdate"
# customMessage=""
# debug="true"


# selfservicePackage="true"

# logoutQueued="true"
# restartQueued="true"
# helpTicketsEnabled="false"
# helpTicketsEnabledViaAppRestriction="false"
# helpTicketsEnabledViaTrigger="false"
# helpTicketsEnabledViaFunction="false"

##########################################################################################
#								Package name Processing									 #
##########################################################################################

#### Caching detection ####
waitingRoomDIR="/Library/Application Support/JAMF/Waiting Room/"

uexNameConsolidated="$NameConsolidated"



##########################################################################################
# 										LOGGING PREP									 #
##########################################################################################
logname="$uexNameConsolidated"
logfilename="$logname".log
logdir="$UEXFolderPath/UEX_Logs/"
resulttmp="$logname"_result.log


mkdir -p "$logdir" > /dev/null 2>&1
chmod -R 755 "$logdir"

logfilepath="$logdir""$logfilename"
resultlogfilepath="$logdir""$resulttmp"


linkaddress="/Library/Logs/"
ln -s "$logdir" "$linkaddress" > /dev/null 2>&1

compname=$( scutil --get ComputerName )
chmod -R 777 "$logdir"

##########################################################################################
# 										LOGGING PREP									 #
##########################################################################################
logname="$uexNameConsolidated"
logfilename="$logname".log
logdir="$UEXFolderPath/UEX_Logs/"
resulttmp="$logname"_result.log


mkdir "$logdir" > /dev/null 2>&1
chmod -R 755 "$logdir"

logfilepath="$logdir""$logfilename"
resultlogfilepath="$logdir""$resulttmp"


linkaddress="/Library/Logs/"
ln -s "$logdir" "$linkaddress" > /dev/null 2>&1

compname=$( scutil --get ComputerName )
chmod -R 777 "$logdir"

##########################################################################################

##########################################################################################
##									SETTING FOR DEBUG MODE								##
##########################################################################################

debugDIR="$UEXFolderPath/debug/"

if [[ -e "$debugDIR""$uexNameConsolidated" ]] ; then 
	debug=true
fi

if [[ "$debug" == true ]] || [[ "$checks" == *"debug"* ]] ; then 
	echo debug on
	debug=true
else
	## less verbose is better
	# echo debug off
	debug=false
fi


if [[ $debug = true ]] ; then
	"$jhPath" -windowType hud -windowPosition ll -title "$title" -description "UEX Script Running in debug mode." -button1 "OK" -timeout 30 > /dev/null 2>&1 &
	
	mkdir -p "$debugDIR" > /dev/null 2>&1
	touch "$debugDIR""$uexNameConsolidated"
fi


##########################################################################################
##										FUNCTIONS										##
##########################################################################################

getCurrentConsoleUser() {
	/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser;
import sys;
username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0];
username = [username,""][username in [u"loginwindow", None, u""]];
sys.stdout.write(username + "\n");'
	return $?
}


currentConsoleUserName=$( getCurrentConsoleUser )


# Function to determine the logged-in state of the Mac This is for Commands that needs to be run as the user
function DetermineLoginState() {
	# The following line is courtesy of @macmule - https://macmule.com/2014/11/19/how-to-get-the-currently-logged-in-user-in-a-more-apple-approved-way/
	currentConsoleUserName=$( getCurrentConsoleUser )
	if [[ "$currentConsoleUserName" == "" ]] ; then
    	log4_JSS "No user logged in"
		CMD_PREFIX=""
	else
    	log4_JSS "User $currentConsoleUserName is logged in"
    	CMD_PREFIX="sudo -u $currentConsoleUserName "
	fi
	logInUEX4DebugMode "Resolved CMD_PREFIX: $CMD_PREFIX"
}

sCocoaDialog_Pipe="/private/tmp/.cocoadialog_${0##*/}_${$}.pipe"
bCocoaDialog_DisplayIsInitialized=0
CocoaDialogProgressCounter=0

fn_find_Clutter () {
	sudo -u "$loggedInUser" -H open -a "/System/Library/CoreServices/Applications/Storage Management.app"
}

fn_trigger ()
{

	fn_execute_log4_JSS "$jamfBinary policy -forceNoRecon -trigger $1"

}

triggerNgo ()
{
	$jamfBinary policy -forceNoRecon -trigger "$1" &
}


cocoaDialog() {
	/usr/bin/sudo --user "${currentConsoleUserName}" --set-home "${sCocoaDialog_App}" "${@}"
}

_initCocoaDialogProgress () {
	# internal use only
    local sDialogTitle="${1}"
    local sDialogMessage="${2}"
    
    # create a named pipe for displayed messages
    /bin/rm -f "${sCocoaDialog_Pipe}"
    /usr/bin/mkfifo "${sCocoaDialog_Pipe}"
    
    # create a background job which takes its input from the named pipe
    cocoaDialog progressbar \
    				--indeterminate \
    				--title "${sDialogTitle}" \
    				--text "${sDialogMessage}" < "${sCocoaDialog_Pipe}" &
    # associate file descriptor 3 with that pipe and send a character through the pipe
    exec 3<> "${sCocoaDialog_Pipe}"
    echo -n . >&3
    bCocoaDialog_DisplayIsInitialized=1
    
    return 0
}

displayCocoaDialogProgress () {
	# parameters Title, Message, Status Message
    local sDialogTitle="${1}"
    local sDialogMessage="${2}"
    
	if [[ ${bCocoaDialog_DisplayIsInitialized} -eq 0 ]] ; then
		_initCocoaDialogProgress "${sDialogTitle}" "${sDialogMessage}"
	fi
   	
   	echo "${CocoaDialogProgressCounter} ${2}" >&3;
   	sleep 2
   	
   	return 0
}

updateCocoaDialogProgress () {
	# parameter message
	CocoaDialogProgressCounter=$(( CocoaDialogProgressCounter + 1 ))
	if [[ $CocoaDialogProgressCounter -ge 100 ]] ; then
		CocoaDialogProgressCounter=0
	fi
	
	echo "${CocoaDialogProgressCounter} ${1}" >&3;
	sleep 2
	
	return 0
}

cleanupCocoaDialogProgress () {
	if [[ ${bCocoaDialog_DisplayIsInitialized} -ne 0 ]] ; then
		# turn off the progress bar by closing file descriptor 3
		exec 3>&-
		
		# wait for all background jobs to exit
		/usr/bin/wait
		/bin/rm -f "${sCocoaDialog_Pipe}"
	fi
		
	return 0
}

fn_getLoggedinUser () {
	loggedInUser=$(/usr/bin/stat -f%Su /dev/console)
	logInUEX4DebugMode "fn_getLoggedinUser returned $loggedInUser"
}

fn_getPlistValue () {
	/usr/libexec/PlistBuddy -c "print $1" "$UEXFolderPath/$2/$3"
}

fn_addPlistValue () {
	/usr/libexec/PlistBuddy -c "add $1 $2 ${3}" "$UEXFolderPath"/"$4"/"$5" > /dev/null 2>&1

	# log the values of the plist
	logInUEX4DebugMode "Plist Details: $1 $2 $3"
}

fn_setPlistValue () {
	/usr/libexec/PlistBuddy -c "set $1 ${2}" "$UEXFolderPath"/"$3"/"$4" > /dev/null 2>&1

	# log the values of the plist
	logInUEX4DebugMode "Plist Details Updated: $1 $2 $3"

}

fn_checkPKGsForApps () {
for package in "${packages[@]}"; do

	# Break the package check loop if it's already called an update
	if [[ "$checks" == *"update"* ]] ; then
		break
	fi

	# do not use pkgutil to scan .zip or .dmg files (issue #45)
	if [[ $package != *".zip" ]] && [[ $package != *".dmg" ]] ;then
		pathtopkg="$waitingRoomDIR"
		pkg2install="$pathtopkg""$PKG"
		logInUEX4DebugMode "Checking $package for apps that are interacted with."
		local packageContents
		packageContents=$( pkgutil --payload-files "$pkg2install" )

		for app in "${apps[@]}"; do
			#statements
			logInUEX4DebugMode "Check $package for app $app"
			if [[ "$packageContents" == *"$app"* ]] ; then
				#statements 

				loggedInUser=$( /bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root )
				local appfound
				appfound=$( /usr/bin/find /Applications -maxdepth 3 -iname "$app" )
				if [[ -e /Users/"$loggedInUser"/Applications/ ]] ; then
					local userappfound
					userappfound=$( /usr/bin/find /Users/"$loggedInUser"/Applications/ -maxdepth 3 -iname "$app" )
				fi
				
		# 		altpathsfound=""
				for altpath in "${altpaths[@]}" ; do
					
					if [[ "$altpath" == "~"* ]] ; then 
						altpathshort=$( echo "$altpath" | cut -c 2- )
						altuserpath="/Users/${loggedInUser}${altpathshort}"
						if [[ -e "$altuserpath" ]] ; then 
							local foundappinalthpath
							foundappinalthpath=$( /usr/bin/find "$altuserpath" -maxdepth 3 -iname "$app" )
						fi
					else
						if [[ -e "$altpath" ]] ; then		
							local foundappinalthpath
							foundappinalthpath=$( /usr/bin/find "$altpath" -maxdepth 3 -iname "$app" )
						fi
					fi
				done
				if [[ "$foundappinalthpath" ]] || [[ "$userappfound" ]] || [[ "$appfound" ]] ; then
					#statements
				log4_JSS "$package contains $app and app is already found. Classifying as an update"
				checks+=" update"
				break
				fi
				
				
			fi
		done
	fi # package is not a zip or dmg
done
}


logInUEX () {
	echo "$(date)"	"$compname"	:	"$1" >> "$logfilepath"
}

logInUEX4DebugMode () {
	if [[ $debug = true ]] ; then	
		logMessage="-DEBUG- $1"
		logInUEX "$logMessage"
	fi
}

log4_JSS () {
	echo "$(date)"	"$compname"	:	"$1"  | tee -a "$logfilepath"
}

fn_execute_log4_JSS () {
	local dateOfCommand
	dateOfCommand=$( date )
	local TMPresultlogfilepath
	TMPresultlogfilepath="/private/tmp/resultsOfCommand_$dateOfCommand.log"
	
	log4_JSS "Running command: $1"
	$1 >>"$TMPresultlogfilepath"
	local resultsOfCommand
	resultsOfCommand=$( cat "$TMPresultlogfilepath" )
	log4_JSS "RESULT: $resultsOfCommand"
	rm "$TMPresultlogfilepath" 2> /dev/null
}



fn_check4Packages () {

	#checking for the presence of the packages
	if [[ "$suspackage" != true ]] ; then
		pathtopkg="$waitingRoomDIR"
		packageMissing=""
		for PKG in "${packages[@]}"; do
			pkg2install="$pathtopkg""$PKG"
			# echo looking in "$pkg2install"
			if [[ ! -e "$pkg2install" ]] ; then
				packageMissing=true
				log4_JSS "The package $PKG could not be found"
			fi
		done

		if [[ $packageMissing != true ]] ; then
			packageMissing=false
		fi
	fi
}

fn_generatateApps2quit () {
	local logMode
	logMode="$1"
	apps2quit=()
	apps2ReOpen=()
	apps2kill=()
	for app in "${apps[@]}" ; do
		IFS=$'\n'
		## This is needed to get the parent proccess and prevent unwanted blocking
		# shellcheck disable=SC2009
		appid=$( ps aux | grep "$app/Contents/MacOS/" | grep -v grep | grep -v jamf | awk '{ print $2 }' )
		# Processing application $app
		if  [ "$appid" != "" ] ; then
				app2Open=""
				appFound=""
				userAppFound=""
				# Find the apss in /Applications/ and ~/Applications/ and open as the user
				if [[ "$checks" != *"uninstall"* ]] ; then
					appFound=$( /usr/bin/find "/Applications" -maxdepth 3 -iname "$app" )
					userAppFound=$( /usr/bin/find "$loggedInUserHome/Applications" -maxdepth 3 -iname "$app" 2> /dev/null )
				fi
				
				
				if [[ "$appFound" ]] || [[ "$userAppFound" ]] ; then
					apps2ReOpen+=("${app}")
					apps2kill+=("${app}")
				else
					apps2quit+=("${app}")
					apps2kill+=("${app}")
				fi
			if [[ $logMode = areyousure ]] ;then
				log4_JSS "$app is stil running. Loading Are You Sure Window"
			elif [[ $logMode = beforedialog ]] ;then
				log4_JSS "$app is running. Notification Required"
			elif [[ $logMode = safequit ]] && [[ "$checks" != *"nopreclose"* ]];then
				log4_JSS "$app is stil running. Attempting to safely quit the App."
			fi

		fi
	done
	unset IFS
}

fn_waitForApps2Quit () {
	appsRunning=()
	for app in "${apps[@]}" ; do
		IFS=$'\n'
		## This is needed to get the parent proccess and prevent unwanted blocking
		# shellcheck disable=SC2009
		appid=$( ps aux | grep "$app/Contents/MacOS/" | grep -v grep | grep -v jamf | awk '{ print $2 }' )
		# Processing application $app
		if  [ "$appid" != "" ] ; then
			appsRunning+=("${app}")

		fi
	done

	if [[ "${appsRunning[*]}" != *".app"* ]] ; then
		log4_JSS "User has closed all apps needed. Continuing $action"
		echo 1 > "$PostponeClickResultFile"
		apps2Relaunch=("${apps2ReOpen[@]}")
		killall jamfHelper
	fi
}

fn_waitForApps2Quit4areYouSure () {
	appsRunning=()
	for app in "${apps[@]}" ; do
		IFS=$'\n'
		## This is needed to get the parent proccess and prevent unwanted blocking
		# shellcheck disable=SC2009
		appid=$( ps aux | grep "$app/Contents/MacOS/" | grep -v grep | grep -v jamf | awk '{ print $2 }' )
		# Processing application $app
		if  [ "$appid" != "" ] ; then
			appsRunning+=("${app}")

		fi
		unset IFS
	done

	if [[ "${appsRunning[*]}" != *".app"* ]] ; then
		log4_JSS "User has closed all apps needed. Continuing $action"
		echo 0 > "$areYouSureClickResultFile"
		apps2Relaunch=("${apps2ReOpen[@]}")
		killall jamfHelper
	fi
}


fn_check4KeynoteRunningAndActiveInPresentationMode () {
# KeynotePlaying=$( lsof -p $(pgrep 'Keynote' | awk '{print $1}') | grep "/Resources/KeynotePlaying.icns" )
KeynotePlaying=$( pmset -g assertions )


if [[ "$KeynotePlaying" == *"Displaying Keynote slideshow"* ]];then
	log4_JSS "User is in Presentation Mode on Keynote and its currently the Active Screen"
	presentationRunning=true
fi
}

fn_check4PowerPointRunningInPresentationMode () {
PowerPointPlaying=$( pmset -g assertions | grep "Microsoft PowerPoint" )
if [[ "$PowerPointPlaying" == *"Slide Show"* ]];then
	log4_JSS "User is in Presentation Mode on Microsoft PowerPoint"
	presentationRunning=true
fi
}

fn_check4ActiveScreenSharingInSkypeForBusiness () {
## This is needed to get the parent proccess and prevent unwanted blocking
# shellcheck disable=SC2009
S4Bscreensharing=$( lsof -p "$(ps -A | grep -m1 'Skype for Business' | awk '{print $1}')" | grep "Resources/ScreenSharingIndicator.storyboardc" )
if [[ "$S4Bscreensharing" == *"ScreenSharingIndicator.storyboardc"* ]] ; then
	log4_JSS "User is sharing their screen on Skype for Business."
	presentationRunning=true
fi
}


fn_check4ScreenSharingSessionInWebExMeetingCenter () {
## This is needed to get the parent proccess and prevent unwanted blocking
# shellcheck disable=SC2009
webExScreenSharing=$( lsof -p "$(ps -A | grep -m1 'Meeting Center.app' | awk '{print $1}')" | grep "NF_Button_Stop_default.tiff" )
if [[ "$webExScreenSharing" == *"NF_Button_Stop_default.tiff"* ]] ; then
	log4_JSS "User has been sharing their screen on WebEx Meeting Center."
	presentationRunning=true
fi
}


fn_check4ActiveScreenSharingInMicrosoftTeams () {
## This is needed to get the parent proccess and prevent unwanted blocking
# shellcheck disable=SC2009
msTeamsLogLocation=$( lsof -p "$(ps -A | grep -m1 'Microsoft Teams' | awk '{print $1}')" | grep -m1 "logs.txt" | tail -n 1 | awk '{ print $9 " " $NF }' )
if [[ -e "$msTeamsLogLocation" ]] ; then
	msTeamsScreensharing=$( grep SharingIndicator "$msTeamsLogLocation" | tail -n 2 )
	if [[ "$msTeamsScreensharing" ]] && [[ "$msTeamsScreensharing" != *"disposing"* ]] ; then
		log4_JSS "User is sharing their screen on Microsoft Teams."
		presentationRunning=true
	fi
fi 

}

fn_check4ScreenSharingSessionInZoomUS () {
## This is needed to get the parent proccess and prevent unwanted blocking
# shellcheck disable=SC2009
zoomUSLogLocation=$( lsof -p "$(ps -A | grep -m1 'zoom.us' | awk '{print $1}')" | grep -m1 "as.log" | tail -n 1 | awk '{ print $NF }' )
if [[ -e "$zoomUSLogLocation" ]] ; then
	zoomUSScreensharing=$( cat "$zoomUSLogLocation" )
	# using if it's not empty because the file might be there but it will be empty 
	if [[ -n "$zoomUSScreensharing" ]] ; then
		log4_JSS "User has been sharing their screen on zoom.us."
		presentationRunning=true
	fi
fi 

}



fn_check4PendingRestartsOrLogout () {
	lastReboot=$( date -jf "%s" "$(sysctl kern.boottime | awk -F'[= |,]' '{print $6}')" "+%s" )
	# lastRebootFriendly=$( date -r$lastReboot )

	## Need the plist as a file name in list format
	# shellcheck disable=SC2010
	resartPlists=$( ls "$UEXFolderPath"/restart_jss/ | grep "plist" )
	set -- "$resartPlists"
	IFS=$'\n'
	##This works because i'm setting the seperator
	# shellcheck disable=SC2206
	# shellcheck disable=SC2048
	declare -a resartPlists=($*)  
	unset IFS

	## Need the plist as a file name in list format
	# shellcheck disable=SC2010
	logoutPlists=$( ls "$UEXFolderPath"/logout_jss/ | grep "plist" )
	set -- "$logoutPlists" 
	IFS=$'\n'
	##This works because i'm setting the seperator
	# shellcheck disable=SC2206
# shellcheck disable=SC2048
	declare -a logoutPlists=($*)  
	unset IFS

	# check for any plist that are scheduled to have a restart
	for i in "${resartPlists[@]}" ; do
		# Check all the plist in the folder for any required actions
		# if the user has already had a fresh restart then delete the plist
		# other wise the advise and schedule the logout.

		local uexNameConsolidated
		uexNameConsolidated=$(fn_getPlistValue "uexNameConsolidated" "restart_jss" "$i")
		local plistrunDate
		plistrunDate=$(fn_getPlistValue "runDate" "restart_jss" "$i")

		local timeSinceReboot
		timeSinceReboot=$( echo "${lastReboot} - ${plistrunDate}" | bc )
		logInUEX "timeSinceReboot is $timeSinceReboot"
		
		local logname
		logname="${uexNameConsolidated//.plist/}"
		local logfilename
		logfilename="$logname".log
		local resulttmp
		resulttmp="$logname"_result.log
		local logfilepath
		logfilepath="$logdir""$logfilename"
		local resultlogfilepath
		resultlogfilepath="$logdir""$resulttmp"
		
		if [[ $timeSinceReboot -gt 0 ]] || [ -z "$plistrunDate" ]  ; then
			# the computer has rebooted since $runDateFriendly
			#delete the plist
			logInUEX "Deleting the restart plsit $i because the computer has rebooted since $runDateFriendly"
			rm "$UEXFolderPath/restart_jss/$i"
		else 
			# the computer has NOT rebooted since $runDateFriendly
			log4_JSS "Other restarts are queued"
			restartQueued=true
		fi
	done


	# if there are no scheduled restart then proceed with logout checks and prompts
	if [[ "$restartQueued" != "true" ]] ; then
		
		for i in "${logoutPlists[@]}" ; do
		# Check all the plist in the folder for any required actions
		# If the plist has already been touched 
		# OR if the user has already had a fresh login then delete the plist
		# other wise the advise and schedule the logout.

			local uexNameConsolidated
			uexNameConsolidated=$(fn_getPlistValue "uexNameConsolidated" "logout_jss" "$i")
			local plistloggedInUser
			plistloggedInUser=$(fn_getPlistValue "loggedInUser" "logout_jss" "$i")
			local checked
			checked=$(fn_getPlistValue "checked" "logout_jss" "$i")
			local plistrunDate
			plistrunDate=$(fn_getPlistValue "runDate" "logout_jss" "$i")

			# local plistrunDateFriendly
			# plistrunDateFriendly=$( date -r $plistrunDate )
			
			# local timeSinceLogin=$((lastLogin-plistrunDate))
			local timeSinceReboot
			timeSinceReboot=$( echo "${lastReboot} - ${plistrunDate}" | bc )
			
			#######################
			# Logging files setup #
			#######################
			local logname
			logname="$uexNameConsolidated"
			local logfilename
			logfilename="$logname".log
			local resulttmp
			resulttmp="$logname"_result.log
			local logfilepath
			logfilepath="$logdir""$logfilename"
			local resultlogfilepath
			resultlogfilepath="$logdir""$resulttmp"
			
			
			if [[ $timeSinceReboot -gt 0 ]] || [ -z "$plistrunDate" ]  ; then
				# the computer has rebooted since $runDateFriendly
				#delete the plist
				rm "$UEXFolderPath/logout_jss/$i"
				logInUEX "There are no restart interactions required"
				logInUEX "Deleted logout plist because the user has restarted already"
				
			elif [[ $checked == "true" ]] ; then
			# if the user has a fresh login since then delete the plist
			# if the plist has been touched once then the user has been logged out once
			# then delete the plist
				rm "$UEXFolderPath/logout_jss/$i"
				logInUEX "Deleted logout plist because the user has logged out already"
			elif [[ "$plistloggedInUser" != "$loggedInUser" ]] ; then
			# if the user in the plist is not the user as the one currently logged in do not force a logout
			# this will skip the processing of that plist
				logInUEX "User in the logout plist is not the same user as the one currently logged in do not force a logout"
			else 
				# the user has NOT logged out since $plistrunDateFriendly				
				# set the logout to true so that the user is prompted
				log4_JSS "Other logouts are queued"
				logoutQueued=true
			fi
		done
	fi

}

##for #38 Check and unmount previous update disks 
fn_EjectPreviouslyMountedUpdateDisks () {
	knownDisks=(
	"Apple_HFS OS X Base System"
	"Apple_HFS macOS High Sierra"
	"Apple_HFS macOS Base System"
	"Apple_HFS RecoveryHDMeta"
	)

	## Eject disks with known names for containing macOS Updates"
	for disk2Eject in "${knownDisks[@]}" ; do
		knownDisksFound=( "$( /usr/sbin/diskutil list | grep "$disk2Eject" | awk '{print$NF}' | sed 's/.\{2\}$//' )")
		for eachKnownDisk in "${knownDisksFound[@]}" ; do
			if [[ "$eachKnownDisk" == *"disk"* ]] ; then
				echo "ejecting disk $eachKnownDisk"
				fn_execute_log4_JSS "/usr/sbin/diskutil eject $eachKnownDisk"
			fi
		done
	done

	## Eject disks with the naming convetion "Apple_HFS macOS 10.1* Update"
	commonDiskNames=( "$( /usr/sbin/diskutil list | grep "Apple_HFS macOS 10.1" | grep "Update" | awk '{print$NF}' | sed 's/.\{2\}$//' )" )
	for eachFoundDisk in "${commonDiskNames[@]}" ; do
		if [[ "$eachFoundDisk" == *"disk"* ]] ; then
			echo "ejecting disk $eachFoundDisk"
			fn_execute_log4_JSS "/usr/sbin/diskutil eject $eachFoundDisk"
		fi
	done
}

##########################################################################################
##								Initial Required Stuff 									##
##########################################################################################

DetermineLoginState

##########################################################################################
##									SSD Calculations									##
##########################################################################################

solidstate=$( /usr/sbin/diskutil info / | grep "Solid State" | awk 'BEGIN { FS=":" } ; { print $2}' )

if [[ "$solidstate" == *"Yes"* ]] ; then
	# log computer has a solid state drive
	solidstate=true
else
	# echo computer does not have a sold state drive or is not specified
	solidstate=false
fi

if [[ $solidstate = true ]] ; then
	installDuration=$((installDuration / 2))
fi

if [[ "$checks" == *"block"* ]] && [[ $installDuration -lt 5 ]] ; then 
	# original_string='i love Suzi and Marry'
	# string_to_replace_Suzi_with=Sara
	# result_string="${original_string/Suzi/$string_to_replace_Suzi_with}"
	checks="${checks/block/quit}"
fi


##########################################################################################
##								Pre Processing of Variables								##
##########################################################################################


IFS=";"
set -- "$NameConsolidated" 
##This works because i'm setting the seperator
# shellcheck disable=SC2206
# shellcheck disable=SC2048
# shellcheck disable=SC2048
declare -a NameConsolidated=($*)

set -- "$triggers" 
##This works because i'm setting the seperator
# shellcheck disable=SC2206
# shellcheck disable=SC2048
declare -a triggers=($*)
UEXpolicyTrigger=$(echo "${triggers[0]}" | tr '[:upper:]' '[:lower:]')
UEXcachingTrigger="$UEXpolicyTrigger""_cache"

if [[ -z "$UEXhelpticketTrigger" ]] ; then 
	#use for Specified help Tickets
	UEXhelpticketTrigger="$UEXpolicyTrigger""_helpticket"
fi

if [[ -z "$ClearHelpTicketRequirementTrigger" ]] ; then 
	#use for Specified help Tickets
	ClearHelpTicketRequirementTrigger="$UEXpolicyTrigger""_clear_helpticket"
fi

unset "triggers[0]"

unset IFS

AppVendor=${NameConsolidated[0]}
AppName=${NameConsolidated[1]}
AppVersion=${NameConsolidated[2]}
spaceRequired=${NameConsolidated[3]}


##########################################################################################
##								PreProcessing of Defer									##
##########################################################################################

IFS=";"
set -- "$maxdeferConsolidated" 
##This works because i'm setting the seperator
# shellcheck disable=SC2206
# shellcheck disable=SC2048
declare -a maxdeferConsolidated=($*)

if [[ $spaceRequired ]] || [[ "${maxdeferConsolidated[*]}" == *";"* ]] ; then
	maxdefer="${maxdeferConsolidated[0]}"
	diskCheckDelaylimit="${maxdeferConsolidated[1]}"
else
	maxdefer="${maxdeferConsolidated[0]}"
fi


if [[ "$checks" == *"compliance"* ]] && [[ $helpTicketsEnabled = true ]] ; then
	checks+=" helpticket"
else
	# Set the delay limit to 9999 if it's not a compliance policy to avoid odd actions
	diskCheckDelaylimit=99999
fi

# set a default disk delay limit if they haven't been set
if [[ "$checks" == *"critical"* ]] && [[ -z "$diskCheckDelaylimit" ]] ;then
	diskCheckDelaylimit=1
elif [[ -z $diskCheckDelaylimit ]] && [[ -z "$diskCheckDelaylimit" ]] ;then
	diskCheckDelaylimit=3
fi

##########################################################################################
##								STATIC VARIABLES FOR CD DIALOGS							##
##########################################################################################

CocoaDialog="$UEXFolderPath/resources/CocoaDialog.app/Contents/MacOS/CocoaDialog"
sCocoaDialog_App="$CocoaDialog"

##########################################################################################
##							STATIC VARIABLES FOR JH DIALOGS								##
##########################################################################################

heading="${AppVendor} ${AppName}"

#requcing redundancy in the please wait dialog
heading4PleaseWait="${AppVendor} ${AppName}"

#if the icon file doesn't exist then set to a standard icon
if [[ -e "$customLogo" ]] ; then
	icon="$customLogo"
else
	icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
fi
##########################################################################################

##########################################################################################
#								SELF SERVICE APP DETECTION								 #
##########################################################################################
## This is needed to get the exact proccess
# shellcheck disable=SC2009
sspolicyRunning=$( ps aux | grep "00-UEX-Install-via-Self-Service" | grep -v grep | grep -v PATH | awk '{print $NF}' | tr '[:upper:]' '[:lower:]' )
## This is needed to get the exact proccess
# shellcheck disable=SC2009
ssUpdatePolicyRunning=$( ps aux | grep "00-UEX-Update-via-Self-Service" | grep -v grep | grep -v PATH | awk '{print $NF}' | tr '[:upper:]' '[:lower:]' )
## This is needed to get the exact proccess
# shellcheck disable=SC2009
ssUninstallPolicyRunning=$( ps aux | grep "00-UEX-Uninstall-via-Self-Service" | grep -v grep | grep -v PATH | awk '{print $NF}' | tr '[:upper:]' '[:lower:]' )

if [[ -e "$SSplaceholderDIR""$uexNameConsolidated" ]] ; then 
	selfservicePackage=true
	 logInUEX "******* SELF SERVICE INSTALL *******"
elif [[ "$sspolicyRunning" == *"$UEXpolicyTrigger"* ]] ; then
	selfservicePackage=true
fi

### if the ss service action is for update
if [[ "$ssUpdatePolicyRunning" == *"$UEXpolicyTrigger"* ]] ; then
	checks+=" update"
	selfservicePackage=true
fi


### if the ss service action is for un unintall
if [[ "$ssUninstallPolicyRunning" == *"$UEXpolicyTrigger"* ]] ; then
	checks+=" uninstall"
	selfservicePackage=true
fi 

## This is needed to get the exact proccess
# shellcheck disable=SC2009
# deploymentpolicyRunning=$( ps aux | grep "00-UEX-Deploy-via-Trigger" | grep -v grep | grep -v PATH | awk '{print $NF}' | tr '[:upper:]' '[:lower:]' )


## This is needed to get the exact proccess
# shellcheck disable=SC2009
silentpolicyRunning=$( ps aux | grep "00-UEX-Install-Silent-via-trigger" | grep -v grep | grep -v PATH | awk '{print $NF}' | tr '[:upper:]' '[:lower:]' )

if [[ "$silentpolicyRunning" == *"$UEXpolicyTrigger"* ]] ; then
	log4_JSS "Deteced Policy is running with Silent-via-trigger script. Forcing the $actionation in the background."
	silentPackage=true
fi

#####
# splash Buddy for DEP
#####
loggedInUser=$( /bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root )
splashBuddyRunning=$( pgrep SplashBuddy )
DEPNotifyRunning=$( pgrep DEPNotify )

AppleSetupDoneFile="/var/db/.AppleSetupDone"

if [[ $splashBuddyRunning ]] ; then
	log4_JSS "SplashBuddy is Running. Forcing the $actionation in the background."
	silentPackage=true
fi

if [[ $DEPNotifyRunning ]] ; then
	log4_JSS "DEPNotify is Running. Forcing the $actionation in the background."
	silentPackage=true
fi

if [[ "$loggedInUser" == "_mbsetupuser" ]] && [[ ! -f "$AppleSetupDoneFile" ]] ; then
	silentPackage=true
	log4_JSS "First time setup running. Allowing all installations to run silently."
fi


#####

if [[ "$checks" == *"ssavail"* ]] ; then
	ssavail=true
fi 


if [[ "$checks" == *"ssavail"* ]] ; then
	ssavail=true
fi 

if [[ $silentPackage != true ]] ; then
	silentPackage=false
fi

if [[ $selfservicePackage != true ]] ; then
	selfservicePackage=false
fi

##########################################################################################

##########################################################################################
##								MS Update Variable Settings								##
##########################################################################################
msupdateBinary="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
# autoUpdateLogFile="/Library/Logs/Microsoft/autoupdate.log"

fn_check_4_msupdate () {
	echo "" > "$msupdateLog"
	echo "" > "$msupdateLogPlist"
	sudo -u "$currentConsoleUserName" "$msupdateBinary" -l | /usr/bin/tee -a "$msupdateLog"
	sudo -u "$currentConsoleUserName" "$msupdateBinary" -l -f p | /usr/bin/tee -a "$msupdateLogPlist"
}


fn_getMSupdatePackageURLs_and_names () {
	IFS=$'\n'
	##only download the delta update
	msUPdatePackageURLS=( "$( grep -v "FullUpdaterLocation" "$msupdateLogPlist" |  grep -A 1 "Location" | /usr/bin/awk -F'<string>|</string>' '{print $2}')" )
	unset IFS
	# echo "msUPdatePackageURLS is: $msUPdatePackageURLS"
}

fn_downloadMSupdatePackages () {
	packages=""
	for msUpdatePackage in "${msUPdatePackageURLS[@]}" ; do
		
		# msUpdatePackageFileName=$( echo "$msUpdatePackage" | sed 's@.*/@@' )
		msUpdatePackageFileName="$( basename "$msUpdatePackage" )"
		# msUpdatePackageFileName="${msUpdatePackage##*/}"
		# log4_JSS "msUpdatePackageFileName is: $msUpdatePackageFileName"


		local MSupdateDownloadDestination
		MSupdateDownloadDestination="$waitingRoomDIR""$msUpdatePackageFileName"
		local tmpMSupdateDownloadDestination
		tmpMSupdateDownloadDestination="/private/tmp/""$msUpdatePackageFileName"
		# create the folder if it's not there
		if [[ ! -d "waitingRoomDIR" ]] ; then 
			mkdir -p "$waitingRoomDIR" 
			chmod 700 "$waitingRoomDIR" 
		fi

		# have it download to a 
		if [[ ! -f "$MSupdateDownloadDestination" ]] ; then

			# delete the temp file just in case
			if [[ -e "$tmpMSupdateDownloadDestination" ]] ; then rm "$tmpMSupdateDownloadDestination" ; fi
			
			# download to temp directory first
			curl -o "$tmpMSupdateDownloadDestination" --silent --remote-name --location "$msUpdatePackage"
			
			# Move to waiting room when done
			mv "$tmpMSupdateDownloadDestination" "$MSupdateDownloadDestination"
		fi

		# if the file exists then add it to the packages variable
		if [[ -f "$MSupdateDownloadDestination" ]] ; then
			# add the package name to the packages variable to use the native isntaller method
			if [[ $packages == *".pkg" ]] ; then  packages+=";" ;  fi
			packages+="$msUpdatePackageFileName"
		else
			log4_JSS "Downloading $msUpdatePackageFileName Failed"
			# msUpdateDownloadFailed=true
		fi

	done
}

if [[ "$checks" == *"msupdate"* ]] ; then
	msupdate=true
fi

if [[ "$msupdate" = true ]] ; then
	log4_JSS "UEX is Running Microsoft Updates"
	msupdateLog="/private/tmp/msupdate.txt"
	msupdateLogPlist="/private/tmp/msupdate.plist"
	/bin/rm "$msupdateLog" > /dev/null 2>&1
	/bin/rm "$msupdateLogPlist" > /dev/null 2>&1
	touch "$msupdateLog"
	touch "$msupdateLogPlist"
	

	if [[ "$selfservicePackage" = true ]] ; then	
		status="Microsoft Software Updates,
checking for updates..."
		"$CocoaDialog" bubble --title "$title" --text "$status" --icon-file "$icon"	
	fi # selfservice package
	log4_JSS "Checking Microsoft Updates"
	
	fn_check_4_msupdate

	fn_getMSupdatePackageURLs_and_names

	fn_downloadMSupdatePackages

	msupdatesUpdatesList=$( cat "$msupdateLog" )

	if [[ "$msupdatesUpdatesList" == *"Updates available:"* ]] || [[ "$debug" == true ]] ; then
		msupdateUpdatesAvail=true
		
	else
		msupdateUpdatesAvail=false
	# 	echo No new software available.
	# 	echo No new software available no interacton required no notice to show
		checks="quit"
		apps="xayasdf.app;asdfasfd.app"
		installDuration=1
		
		skipNotices="true"
		
		if [[ "$selfservicePackage" = true ]] ; then	
			status="Microsoft Updates,
No updates available."
			"$CocoaDialog" bubble --title "$title" --text "$status" --icon-file "$icon"
			sleep 5
		fi # selfservice package
	fi

	msUpdates2RunSilent=()
	msUpdates2RunAfterUEX=()
	if [[ "$msupdateUpdatesAvail" = true ]] ; then
		
		# Do the AutoUpdate Updates First then re check for updates
		if [[ "$msupdatesUpdatesList" == *"AutoUpdate"* ]] ; then
			
			#extract ID of update for msupdate
			# AutoUpdateUpdateID=$( echo "$msupdatesUpdatesList" | grep AutoUpdate | awk '{ print $1 }' )
			# sudo -u "$currentConsoleUserName" "$msupdateBinary" -i -a "$AutoUpdateUpdateID"


				msupdatesUpdatesList=$( cat $msupdateLog )

				if [[ "$msupdatesUpdatesList" == *"Updates available:"* ]] || [[ "$debug" == true ]] ; then
					msupdateUpdatesAvail=true
				else
					msupdateUpdatesAvail=false
				# 	echo No new software available.
				# 	echo No new software available no interacton required no notice to show
					checks="quit"
					apps="xayasdf.app;asdfasfd.app"
					installDuration=1
					
					skipNotices="true"
					
					if [[ "$selfservicePackage" = true ]] ; then	
						status="Microsoft Updates,
No updates available."
						"$CocoaDialog" bubble --title "$title" --text "$status" --icon-file "$icon"
						sleep 5
					fi # selfservice package
				fi
		fi # contains AutoUpdate Update

		# try to run now for all apps it queues them anyway
		if [[ "$msupdatesUpdatesList" == *"Updates available:"* ]] ; then
				msupdateUpdatesAvail=true
				if [[ "$selfservicePackage" != true ]] ; then
					sudo -u "$currentConsoleUserName" "$msupdateBinary" -i &
				fi
		fi


		if [[ "$msupdatesUpdatesList" == *"Outlook"* ]] ; then
			
			#extract ID of update for msupdate
			OutlookUpdateID=$( echo "$msupdatesUpdatesList" | grep Outlook | awk '{ print $1 }' )
	 		# OutlookNoteUpdateName=$( echo "$msupdatesUpdatesList" | grep "Outlook" | awk '{for(i=2; i<=NF; ++i) printf "%s ", $i; print ""}' | xargs )
	 	
	 		## This is needed to get the parent proccess and prevent unwanted blocking
			# shellcheck disable=SC2009
	 		outLookappid=$( ps aux | grep "Microsoft Outlook.app/Contents/MacOS/" | grep -v grep | grep -v jamf | awk '{ print $2 }' )
			# if [[ "$outLookappid" ]] && [[ "$OutlookNoteSilentInstallQueued" ]] ;then
			if [[ "$outLookappid" ]] ;then
				checks+=" block"
				installDuration=20
				if [[ $apps == *".app" ]] ; then  apps+=";" ;  fi
				apps+="Microsoft Outlook.app"
				# For Self Service Queue the install until after it's over
				# msUpdates2RunAfterUEX+=( "$OutlookUpdateID" )
			else
				msUpdates2RunSilent+=( "$OutlookUpdateID" )
			fi # Outlook App is Running
		fi # contains Outlook Update

		if [[ "$msupdatesUpdatesList" == *"Word"* ]] ; then
			
			#extract ID of update for msupdate
			WordUpdateID=$( echo "$msupdatesUpdatesList" | grep Word | awk '{ print $1 }' )
	 		# WordUpdateName=$( echo "$msupdatesUpdatesList" | grep Word | awk '{for(i=2; i<=NF; ++i) printf "%s ", $i; print ""}' | xargs )
	 		# WordSilentInstallQueued=$( cat "$autoUpdateLogFile" | grep "update for silent installation: \"$WordUpdateName\"" )

	 		## This is needed to get the parent proccess and prevent unwanted blocking
			# shellcheck disable=SC2009
	 		Wordappid=$( ps aux | grep "Microsoft Word.app/Contents/MacOS/" | grep -v grep | grep -v jamf | awk '{ print $2 }' )
			# if [[ "$Wordappid" ]] && [[ "$WordSilentInstallQueued" ]] ;then
			if [[ "$Wordappid" ]] ;then
				checks+=" block"
				installDuration=20
				if [[ $apps == *".app" ]] ; then  apps+=";" ;  fi
				apps+="Microsoft Word.app"
				# For Self Service Queue the install until after it's over
				# msUpdates2RunAfterUEX+=( "$WordUpdateID" )
			else
				msUpdates2RunSilent+=( "$WordUpdateID" )
			fi # Word App is Running
		fi # contains Word Update

		if [[ "$msupdatesUpdatesList" == *"PowerPoint"* ]] ; then
			
			#extract ID of update for msupdate
			PowerPointUpdateID=$( echo "$msupdatesUpdatesList" | grep PowerPoint | awk '{ print $1 }' )
	 		# PowerPointNoteUpdateName=$( echo "$msupdatesUpdatesList" | grep "PowerPoint" | awk '{for(i=2; i<=NF; ++i) printf "%s ", $i; print ""}' | xargs )

	 		## This is needed to get the parent proccess and prevent unwanted blocking
			# shellcheck disable=SC2009
	 		PowerPointappid=$( ps aux | grep "Microsoft PowerPoint.app/Contents/MacOS/" | grep -v grep | grep -v jamf | awk '{ print $2 }' )
			# if [[ "$PowerPointappid" ]] && [[ "$PowerPointNoteSilentInstallQueued" ]] ;then
			if [[ "$PowerPointappid" ]] ;then
				checks+=" block"
				installDuration=20
				if [[ $apps == *".app" ]] ; then  apps+=";" ;  fi
				apps+="Microsoft PowerPoint.app"
				# For Self Service Queue the install until after it's over
				# msUpdates2RunAfterUEX+=( "$PowerPointUpdateID" )
			else
				msUpdates2RunSilent+=( "$PowerPointUpdateID" )
			fi # PowerPoint App is Running
		fi # contains PowerPoint Update

		if [[ "$msupdatesUpdatesList" == *"Excel"* ]] ; then
			
			#extract ID of update for msupdate
			ExcelUpdateID=$( echo "$msupdatesUpdatesList" | grep Excel | awk '{ print $1 }' )
			# ExcelUpdateName=$( echo "$msupdatesUpdatesList" | grep Excel | awk '{for(i=2; i<=NF; ++i) printf "%s ", $i; print ""}' | xargs )
	 		# ExcelSilentInstallQueued=$( cat "$autoUpdateLogFile" | grep "update for silent installation: \"$ExcelUpdateName\"" )

	 		## This is needed to get the parent proccess and prevent unwanted blocking
			# shellcheck disable=SC2009
	 		Excelappid=$( ps aux | grep "Microsoft Excel.app/Contents/MacOS/" | grep -v grep | grep -v jamf | awk '{ print $2 }' )
			# if [[ "$Excelappid" ]] && [[ "$ExcelSilentInstallQueued" ]];then
			if [[ "$Excelappid" ]];then
				checks+=" block"
				installDuration=20
				if [[ $apps == *".app" ]] ; then  apps+=";" ;  fi
				apps+="Microsoft Excel.app"
				# For Self Service Queue the install until after it's over
				# msUpdates2RunAfterUEX+=( "$ExcelUpdateID" )
			else
				msUpdates2RunSilent+=( "$ExcelUpdateID" )
			fi # Excel App is Running
		fi # contains Excel Update

		## Teams with MAU is not supported yet
		# if [[ "$msupdatesUpdatesList" == *"Teams"* ]] ; then
			
		# 	#extract ID of update for msupdate
		# 	TeamsUpdateID=$( echo "$msupdatesUpdatesList" | grep Teams | awk '{ print $1 }' )
	 # 		Teamsappid=$( ps aux | grep "Microsoft Teams.app/Contents/MacOS/" | grep -v grep | grep -v jamf | awk '{ print $2 }' )
		# 	if [[ "$Teamsappid" ]] ;then
		# 		checks+=" block"
		installDuration=20
		# 		if [[ $apps == *".app" ]] ; then  apps+=";" ;  fi
		# 		apps+="Microsoft Teams.app"
			## For Self Service Queue the install until after it's over# 	
			msUpdates2RunAfterUEX+=( "$TeamsUpdateID" )
			# else
			# 	msUpdates2RunSilent+=( "$TeamsUpdateID" )
		# 	fi # Teams App is Running
		# fi # contains Teams Update

		## OneDrive with MAU is not supported yet
		# if [[ "$msupdatesUpdatesList" == *"OneDrive"* ]] ; then
			
		# 	#extract ID of update for msupdate
		# 	OneDriveUpdateID=$( echo "$msupdatesUpdatesList" | grep OneDrive | awk '{ print $1 }' )
	 # 		OneDriveappid=$( ps aux | grep "OneDrive.app/Contents/MacOS/" | grep -v grep | grep -v jamf | awk '{ print $2 }' )
		# 	if [[ "$OneDriveappid" ]] ;then
		# 		checks+=" block"
		installDuration=20
		# 		if [[ $apps == *".app" ]] ; then  apps+=";" ;  fi
		# 		apps+="OneDrive.app"
			## For Self Service Queue the install until after it's over# 	
			msUpdates2RunAfterUEX+=( "$OneDriveUpdateID" )
			# else
			# 	msUpdates2RunSilent+=( "$OneDriveUpdateID" )
		# 	fi # OneDrive App is Running
		# fi # contains OneDrive Update

		if [[ "$msupdatesUpdatesList" == *"OneNote"* ]] ; then
			
			#extract ID of update for msupdate
			OneNoteUpdateID=$( echo "$msupdatesUpdatesList" | grep OneNote | awk '{ print $1 }' )
	 		# OneNoteUpdateName=$( echo "$msupdatesUpdatesList" | grep OneNote | awk '{for(i=2; i<=NF; ++i) printf "%s ", $i; print ""}' | xargs )
	 		# OneNoteSilentInstallQueued=$( cat "$autoUpdateLogFile" | grep "update for silent installation: \"$OneNoteUpdateName\"" )

	 		## This is needed to get the parent proccess and prevent unwanted blocking
			# shellcheck disable=SC2009
	 		OneNoteappid=$( ps aux | grep "Microsoft OneNote.app/Contents/MacOS/" | grep -v grep | grep -v jamf | awk '{ print $2 }' )
			# if [[ "$OneNoteappid" ]] && [[ "$OneNoteSilentInstallQueued" ]] ;then
			if [[ "$OneNoteappid" ]] ;then
				checks+=" block"
				installDuration=20
				if [[ $apps == *".app" ]] ; then  apps+=";" ;  fi
				apps+="Microsoft OneNote.app"
				# For Self Service Queue the install until after it's over
				# msUpdates2RunAfterUEX+=( "$OneNoteUpdateID" )
			else
				msUpdates2RunSilent+=( "$OneNoteUpdateID" )
			fi # OneNote App is Running
		fi # contains OneNote Update

		if [[ "$msupdatesUpdatesList" == *"Skype For Business"* ]] ; then
			
			#extract ID of update for msupdate
			SFBUpdateID=$( echo "$msupdatesUpdatesList" | grep "Skype For Business" | awk '{ print $1 }' )
	 		# SFBNoteUpdateName=$( echo "$msupdatesUpdatesList" | grep "Skype For Business" | awk '{for(i=2; i<=NF; ++i) printf "%s ", $i; print ""}' | xargs )
	 		# SFBNoteSilentInstallQueued=$( cat "$autoUpdateLogFile" | grep "update for silent installation: \"$OneNoteUpdateName\"" )

	 		## This is needed to get the parent proccess and prevent unwanted blocking
			# shellcheck disable=SC2009
	 		SFBappid=$( ps aux | grep "Skype for Business.app/Contents/MacOS/" | grep -v grep | grep -v jamf | awk '{ print $2 }' )
			# if [[ "$SFBappid" ]] && [[ "$SFBNoteSilentInstallQueued" ]] ;then
			if [[ "$SFBappid" ]] ;then
				checks+=" block"
				installDuration=20
				if [[ $apps == *".app" ]] ; then  apps+=";" ;  fi
				apps+="Skype for Business.app"
				# For Self Service Queue the install until after it's over
				# msUpdates2RunAfterUEX+=( "$SFBUpdateID" )
			else
				msUpdates2RunSilent+=( "$SFBUpdateID" )
			fi # SFB App is Running
		fi # contains SFB Update

		if [[ -z "$apps" ]] ; then
			log4_JSS "No Microsoft Apps Running that need an update. Suppressing Posponement Dialog"
			checks="quit msupdate"
			apps="xayasdf.app;asdfasfd.app"
			installDuration=1
			skipNotices="true"
		fi


	fi
fi #msupdate are true

##########################################################################################
##								Apple SUS Variable Settings								##
##########################################################################################

if [[ "$checks" == *"suspackage"* ]] ; then
	suspackage=true
fi

if [[ "$suspackage" = true ]] ; then
	appleSUSlog="/private/tmp/swu.log"


	if [[ "$selfservicePackage" = true ]] ; then	
		status="Software Updates,
checking for updates..."
		"$CocoaDialog" bubble --title "$title" --text "$status" --icon-file "$icon"	
	fi # selfservice package

	if [[ $susSetByTrigger = true ]] ;then
		fn_trigger "$susSettingTriggerName"
	fi #


	softwareupdate -l > "$appleSUSlog"

	appleUpdates=$( cat $appleSUSlog )


		
	if [[ "$appleUpdates" == *"*"* ]] || [[ "$debug" == true ]] ; then # update are avlaible
		appleUpdatesAvail=true
		installDuration=5
		if [[ "$selfservicePackage" = true ]] ; then	
			status="Software Updates,
Downloading updates."
			"$CocoaDialog" bubble --title "$title" --text "$status" --icon-file "$icon"
		fi # selfservice package
		# pre download updates
		fn_execute_log4_JSS "softwareupdate -d --all"

	else 
		appleUpdatesAvail=false
	# 	echo No new software available.
	# 	echo No new software available no interacton required no notice to show
		checks="quit"
		apps="xayasdf.app;asdfasfd.app"
		installDuration=1
		
		skipNotices="true"
		
		if [[ "$selfservicePackage" = true ]] ; then	
			status="Software Updates,
No updates available."
			"$CocoaDialog" bubble --title "$title" --text "$status" --icon-file "$icon"
			sleep 5
		fi # selfservice package
	fi

	if [[ $appleUpdatesAvail = true ]] ; then 
		
		echo starting install checks

		appleUpdatesAvail=true

		if [[ "$appleUpdates" == *"Security"* ]] ; then
			checks+=" critical"
			checks+=" compliance"
			installDuration=5
		fi


		if [[ "$appleUpdates" == *"OS X"* ]] ; then
			checks+=" power"
			checks+=" compliance"
			installDuration=45
			diagblock=true
		fi
		
		if [[ "$appleUpdates" == *"macOS"* ]] ; then
			checks+=" power"
			checks+=" compliance"
			installDuration=45
			diagblock=true
		fi
		
		if [[ "$appleUpdates" == *"Firmware"* ]] ; then
			checks+=" power"
			checks+=" restart"
			checks+=" compliance"
			log4_JSS "contains Firmware Update"
		fi

		if [[ "$appleUpdates" == *"restart"* ]] ; then
			checks+=" restart"
			log4_JSS "requires restart"
		fi
		
		if [[ "$appleUpdates" == *"iTunes"* ]] && [[ "$appleUpdates" == *"Safari"* ]] ; then
			checks+=" block"
			installDuration=20
			apps+="iTunes.app;Safari.app"
		elif [[ "$appleUpdates" == *"iTunes"* ]] ; then
			checks+=" block"
			installDuration=20
			apps+="iTunes.app"
# 			echo contains restart and iTunes updates
		elif [[ "$appleUpdates" == *"Safari"* ]] ; then
			checks+=" block"
			installDuration=20
			apps+="Safari.app"
			log4_JSS "contains restart and safari updates"
		fi

		if [[ "$checks" == "" ]] ;then
			checks+=" quit"
			installDuration=1
			skipNotices="true"
		fi
		
		if [[ "$apps" == "" ]] && [[ "$checks" == "" ]] ;then
			checks+=" quit"
			apps="xayasdf.app;asdfasfd.app"
		fi

		##This is looking explicitly for the * character
		# shellcheck disable=SC2063
		updatesfiltered=$( grep "*" -A 1 "$appleSUSlog" | grep -v "*" | awk -F ',' '{print $1}' | awk -F '\t' '{print $2}' | sed '/^\s*$/d' )

		set -- "$updatesfiltered" 
		IFS="--"
		##This works because i'm setting the seperator
		# shellcheck disable=SC2206
# shellcheck disable=SC2048
		declare -a updatesfiltered=($*)  
		unset IFS

		log4_JSS '**Updates Available**'

		log4_JSS "${updatesfiltered[@]}" 
	fi
fi

##########################################################################################
##							List Creations and PLIST Variables							##
##########################################################################################

#need to produce blocking lost for plist 
apps4plist="$apps"
# packages4plist="$packages"

#Separate list of

# oldIFS=IFS
IFS=";"

set -- "$apps"
##This works because i'm setting the seperator
# shellcheck disable=SC2206
# shellcheck disable=SC2048
declare -a apps=($*)

set -- "$packages"
##This works because i'm setting the seperator
# shellcheck disable=SC2206
# shellcheck disable=SC2048
declare -a packages=($*)

unset IFS


##########################################################################################
##						DO NOT MAKE ANY CHANGES BELOW THIS LINE!						##
##########################################################################################

#set to true to skip some errors

##########################################################################################
#								RESOURCE LOADER											 #
##########################################################################################

# only check for the self service icon image if the use is using a custom one
if [[ "$SelfServiceIcon" != *"com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"* ]] ; then
	SelfServiceIconCheck="$SelfServiceIcon"
fi

# only check for the self service icon image if the use is using a custom one
if [[ "$customLogo" != *"Jamf.app/Contents/Resources/AppIcon.icns"* ]] ; then
	customLogoCheck="$customLogo"
fi

# only check for the disk icon image if the use is using a custom one
if [[ "$diskicon" != *"/System/Library/Extensions/IOStorageFamily.kext/Contents/Resources/Internal.icns"* ]] ; then
	diskiconCheck="$diskicon"
fi

# only check for the disk icon image if the use is using a custom one
if [[ "$helpTicketsEnabledViaAppRestriction" = true ]] ; then
	restrictedAppNameCheck="$restrictedAppName"
fi


resources=(
"$customLogoCheck"
"$SelfServiceIconCheck"
"$diskiconCheck"
"$restrictedAppNameCheck"
"$UEXFolderPath/resources/cocoaDialog.app"
"$UEXFolderPath/resources/battery_white.png"
"$UEXFolderPath/resources/PleaseWait.app"
)
for i in "${resources[@]}"; do
	# resourceName="$(echo "$i" | sed 's@.*/@@')"
	# resourceName="${i##*/}"
	# pathToResource="$( dirname "$i" )"
   if [[ ! -e "$i" ]] && [[ "$i" ]] ; then
      # does not exist...
      missingResources=true
   fi
done

if [[ $missingResources = true ]] ; then
	fn_trigger "uexresources"
fi


#if the icon file doesn't exist then set to a standard icon
if [[ -e "$SelfServiceIcon" ]] ; then
	icon="$SelfServiceIcon"
elif [[ -e "$customLogo" ]] ; then
	icon="$customLogo"
else
	icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
fi

#in case the disk icon cannot be found then set the the default
if [[ -e "$diskicon" ]] ; then
	diskicon="/System/Library/Extensions/IOStorageFamily.kext/Contents/Resources/Internal.icns"
fi

##########################################################################################

##########################################################################################
##							Default variables for  Post install							##
##########################################################################################
## Not needed ...yet
# pathToScript=$0
# targetLocation=$2
# targetVolume=$3
##########################################################################################

#need to produce blocking lost for plist 
apps2block="$apps4plist"

##########################################################################################
##								Date for Plists Creation								##
##########################################################################################
runDate=$( date +%s )
runDateFriendly="$( date -r "$runDate" )"
##########################################################################################

##########################################################################################
#								Package name Processing									 #
##########################################################################################

SSplaceholderDIR="$UEXFolderPath/selfservice_jss/"



##########################################################################################


##########################################################################################
##								MAKE DIRECTORIES FOR PLISTS								##
##########################################################################################
blockJSSfolder="$UEXFolderPath/block_jss/"
deferJSSfolder="$UEXFolderPath/defer_jss/"
logoutJSSfolder="$UEXFolderPath/logout_jss/"
restartJSSfolder="$UEXFolderPath/restart_jss/"
selfServiceJSSfolder="$SSplaceholderDIR"
installJSSfolder="$UEXFolderPath/install_jss/"

plistFolders=(
"$blockJSSfolder"
"$deferJSSfolder"
"$logoutJSSfolder"
"$restartJSSfolder"
"$selfServiceJSSfolder"
"$installJSSfolder"
)

for i in "${plistFolders[@]}" ; do 
	if [[ ! -e "$i" ]] ; then 
		mkdir "$i" > /dev/null 2>&1 
	fi 
done

##########################################################################################

##########################################################################################
##								FIX	PERMISSIONS ON RESOURCES							##
##########################################################################################
chmod 644 /Library/LaunchDaemons/github.cubandave.UEX-*  > /dev/null 2>&1
chmod -R 755 "$UEXFolderPath"  > /dev/null 2>&1
##########################################################################################


##########################################################################################
##								FIX	ONWERSHIP ON RESOURCES								##
##########################################################################################
chown root:wheel /Library/LaunchDaemons/github.cubandave.UEX-* > /dev/null 2>&1
chown -R root:wheel "$UEXFolderPath" > /dev/null 2>&1
##########################################################################################

##########################################################################################
# 										LOGGING PREP									 #
##########################################################################################
logname="$uexNameConsolidated"
logfilename="$logname".log
logdir="$UEXFolderPath/UEX_Logs/"
resulttmp="$logname"_result.log


mkdir "$logdir" > /dev/null 2>&1
chmod -R 755 "$logdir"

logfilepath="$logdir""$logfilename"
resultlogfilepath="$logdir""$resulttmp"


linkaddress="/Library/Logs/"
ln -s "$logdir" "$linkaddress" > /dev/null 2>&1

compname=$( scutil --get ComputerName )
chmod -R 777 "$logdir"

#Empty lines
logInUEX "" 
logInUEX "" 
#first log entry
logInUEX "******* Jamf Interaction started *******"
logInUEX4DebugMode "DEBUG MODE: ON"

##########################################################################################

logInUEX "******* START UEX Detail ******"
logInUEX "User Experience Version: $uexvers"
logInUEX "AppVendor=$AppVendor"
logInUEX "AppName=$AppName"
if [[ "$spaceRequired" ]] ; then
	logInUEX "spaceRequired=$spaceRequired"
fi
logInUEX "checks=$checks"
if [[ "$checks" == *"quit"* ]] || [[ "$checks" == *"block"* ]] ; then logInUEX "apps=$apps2block" ; fi
logInUEX "altpaths=${altpaths[*]}"
logInUEX "maxdefer=$maxdefer"

if [[ $diskCheckDelaylimit ]] ; then 
	logInUEX "diskCheckDelaylimit=$diskCheckDelaylimit"
fi
logInUEX "packages=${packages[*]}"
logInUEX "******* END UEX Detail ******"

logInUEX "******* script started ******"


##########################################################################################
##									RESOURCE CHECKS										##
##########################################################################################


if [[ ! -e "$jamfBinary" ]] ; then 
"$CocoaDialog" ok-msgbox --icon caution --title "$title" --text "Error"  \
    --informative-text "There is Scheduled $action being attempted but the computer doesn't have JAMF Management software installed correctly. Please contact $ServiceDeskName for support." \
    --float --no-cancel
    badvariable=true
    logInUEX "ERROR: JAMF binary not found"
fi

jamfhelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
if [[ ! -e "$jamfhelper" ]] ; then 
"$CocoaDialog" ok-msgbox --icon caution --title "$title" --text "Error"  \
    --informative-text "There is Scheduled $action being attempted but the computer doesn't have JAMF Management software installed correctly. Please contact $ServiceDeskName for support." \
    --float --no-cancel
    badvariable=true
    logInUEX "ERROR: jamfHelper not found"
fi

if [[ ! -e "$CocoaDialog" ]] ; then 
"$jhPath" -windowType hud -windowPostion center -button1 OK -title Warning -description "cocoaDialog is not in the resources folder" -icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
badvariable=true
logInUEX "ERROR: cocoDialog not found"

fi

##########################################################################################
##					 Wrapping errors that need to be skipped for debugging				##
##########################################################################################

##########################################################################################
# if [ $debug != true ] ; then
##########################################################################################

##########################################################################################

# fi
##########################################################################################

##########################################################################################
##									Checking for errors									##
##########################################################################################


if [[ "$helpTicketsEnabled" == true ]] && [[ "$helpTicketsEnabledViaAppRestriction" != true ]] && [[ "$helpTicketsEnabledViaTrigger" != true ]] && [[ "$helpTicketsEnabledViaFunction" != true ]] ; then
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'helpTicketsEnabled' is not set correctly. 
	
You need to configure UEX with a method of how you would like to be notified of users needing a help ticket to clear space."
	badvariable=true
	logInUEX "ERROR: The variable 'AppVendor' is not set correctly."
fi
##########################################################################################
if [[ -z $AppVendor ]] ; then
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'AppVendor' is blank"
	badvariable=true
	logInUEX "ERROR: The variable 'AppVendor' is blank"

fi
##########################################################################################
if [[ -z $AppName ]] ; then
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'AppName' is blank"
	badvariable=true
	logInUEX "ERROR: The variable 'AppName' is blank"

fi
##########################################################################################
if [[ -z $AppVersion ]] ; then
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'AppVersion' is blank"
	badvariable=true
	logInUEX "ERROR: The variable 'AppVersion' is blank"

fi

##########################################################################################
if [[ "$checks" != *"quit"* ]] && [[ "$checks" != *"block"* ]] && [[ "$checks" != *"logout"* ]] && [[ "$checks" != *"restart"* ]] && [[ "$checks" != *"notify"* ]] && [[ "$checks" != *"custom"* ]] && [[ "$checks" != *"saveallwork"* ]] && [[ "$checks" != *"suspackage"* ]] && [[ "$checks" != *"msupdate"* ]] && [[ "$checks" != *"macosupgrade"* ]] ; then
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'checks' is not set correctly. 
	
It must be set to 'quit' or 'block' or 'logout' or 'restart' or 'notify' or 'saveallwork' or 'suspackage'."
	badvariable=true
	logInUEX "ERROR: The variable 'checks' is not set correctly."
fi
##########################################################################################
for app in "${apps[@]}" ; do

	if [[ "$checks" == *"quit"* ]] && [[ "$app" != *".app" ]] ; then
		"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
		--informative-text "Error: The variable, ${app}, in 'apps' is not set correctly. 
	
	It must contain the file name for the applicaiton. ie 'Safari.app'."
		badvariable=true
		logInUEX "ERROR: The variable, ${app}, in 'apps' is not set correctly."
	fi
	##########################################################################################
	if [[ "$checks" == *"block"* ]] && [[ "$app" != *".app" ]] ; then
		"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
		--informative-text "Error: The variable, ${app}, in 'apps' is not set correctly. 
	
	It must contain the file name for the applicaiton. ie 'Safari.app'."
		badvariable=true
		logInUEX "ERROR: The variable, ${app}, in 'apps' is not set correctly."
	fi
done
##########################################################################################
if [[ -z $installDuration ]] ; then
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'installDuration' is not set correctly. 
	
It must be an integer greater than 0."
	badvariable=true
	logInUEX "ERROR: The variable 'installDuration' is not set correctly."
fi
##########################################################################################
if [[ -z $maxdefer ]] ; then
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'maxdefer' is not set correctly. 
	
It must be an integer greater or equal to 0."
	badvariable=true
	logInUEX "ERROR: The variable 'maxdefer' is not set correctly."
fi
##########################################################################################
if [[ $installDuration =~ ^-?[0-9]+$ ]] ; then 
	echo integer > /dev/null 2>&1 &
else
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'installDuration' is not set correctly. 
	
It must be an integer greater than 0."
	badvariable=true
	logInUEX "ERROR: The variable 'installDuration' is not set correctly."
fi
##########################################################################################
if [[ $spaceRequired ]] && [[ $spaceRequired =~ ^-?[0-9]+$ ]] ; then 
	echo integer > /dev/null 2>&1 &
elif [[ $spaceRequired ]] ; then 
# this implies to only check this if it's not a variable.
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'spaceRequired' is not set correctly. 
	
It must be an integer greater than 0."
	badvariable=true
	logInUEX "ERROR: The variable 'installDuration' is not set correctly."
fi
##########################################################################################
if [[ $diskCheckDelaylimit ]] && [[ $diskCheckDelaylimit =~ ^-?[0-9]+$ ]] ; then 
	echo integer > /dev/null 2>&1 &
elif [[ $diskCheckDelaylimit ]] ; then 
# this implies to only check this if it's not a variable.
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'diskCheckDelaylimit' is not set correctly. 
	
It must be an integer greater than 0."
	badvariable=true
	logInUEX "ERROR: The variable 'installDuration' is not set correctly."
fi
##########################################################################################
if [[ $maxdefer =~ ^-?[0-9]+$ ]] ; then 
	echo integer > /dev/null 2>&1 &
else
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'maxdefer' is not set correctly. 
	
It must be an integer greater or equal to 0."
	badvariable=true
	logInUEX "ERROR: The variable 'maxdefer' is not set correctly."
fi
##########################################################################################
if [[ "$apps2block" == *";"* ]] && [[ "$apps2block" == *"; "* ]] ; then
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'apps' is not set correctly. 
	
Application names must be sepratated by ';' but cannot contain spaces before or after the ';'."
	badvariable=true
	logInUEX "ERROR: The variable 'apps' is not set correctly. It contains spaces between the delimiters."
fi
##########################################################################################
if [[ "$apps2block" == *";"* ]] && [[ "$apps2block" == *" ;"* ]] ; then
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'apps' is not set correctly. 
	
Application names must be sepratated by ';' but cannot contain spaces before or after the ';'."
	badvariable=true
	logInUEX "ERROR: The variable 'apps' is not set correctly. It contains spaces between the delimiters."
fi
##########################################################################################


##########################################################################################
##					 Wrapping errors that need to be skipped for debugging				##
##########################################################################################

##########################################################################################
if [[ $debug != true ]] ; then
##########################################################################################

	if [[ ! -e "$CocoaDialog" ]] ; then
		failedInstall=true
	fi
##########################################################################################


##########################################################################################	
if [[ "$AppVendor" == *"AppVendor"* ]] ; then
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'AppVendor' is not set correctly. 
	
Please update it from the default."
# 	badvariable=true
	logInUEX "ERROR: The variable 'AppVendor' is not set correctly."
fi
##########################################################################################
if [[ "$AppName" == *"AppName"* ]] ; then
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'AppName' is not set correctly. 
	
Please update it from the default."
# 	badvariable=true
	logInUEX "ERROR: The variable 'AppName' is not set correctly."

fi
##########################################################################################
if [[ "$AppVersion" == *"AppVersion"* ]] ; then
	"$CocoaDialog" ok-msgbox --icon caution --float --no-cancel --title "$title" --text "Error" \
    --informative-text "Error: The variable 'AppVersion' is not set correctly. 
	
Please update it from the default."
# 	badvariable=true
	logInUEX "ERROR: The variable 'AppVersion' is not set correctly."

fi

##########################################################################################
##					 			ENDING WRAP FOR DEBUG ERRORS							##
##########################################################################################
fi
##########################################################################################


##########################################################################################
##									Wrapping errors in 									##
##########################################################################################
if [[ $badvariable != true ]] ; then
##########################################################################################


##########################################################################################
##									 Please Wait Variables								##
##########################################################################################

#PleaseWaitApp="$UEXFolderPath/resources/PleaseWait.app/Contents/MacOS/PleaseWait"
PleaseWaitApp="$UEXFolderPath/resources/PleaseWait.app"
pleasewaitPhase="/private/tmp/com.pleasewait.phase"
pleasewaitProgress="/private/tmp/com.pleasewait.progress"
pleasewaitInstallProgress="/private/tmp/com.pleasewait.installprogress"

##########################################################################################
##									 Battery Test										##
##########################################################################################


Laptop=$( system_profiler SPHardwareDataType | grep -E "MacBook" )
modelName=$( system_profiler SPHardwareDataType | grep "Model Name" | awk -F ': ' '{ print $2 }' )
VmTest=$( ioreg -l | grep -e Manufacturer -e 'Vendor Name' | grep 'Parallels\|VMware\|Oracle\|VirtualBox' | grep -v IOAudioDeviceManufacturerName )
if [[ "$VmTest" ]] ; then 
	Laptop="MacBook" 
fi
fn_BatteryStatus () {

pmset -g batt
}

batteryCustomIcon="$UEXFolderPath/resources/battery_white.png"

#if the icon file doesn't exist then set to a standard icon
if [[ -e "$batteryCustomIcon" ]] ; then
	baticon="$batteryCustomIcon"
else
	baticon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
fi

if [[ "$( fn_BatteryStatus )" =~ "AC" ]] ; then
	#on AC power
	log4_JSS "Computer on AC power"
else
	#on battery power
	log4_JSS "Computer on battery power"
fi


##########################################################################################
##								Pre-Processing Paramaters (APPS)						##
##########################################################################################


# user needs to be notified about all applications that need to be blocked
# Create dialog list with each item on a new line for the dialog windows
# If the list is too long then put two on a line separated by ||
if [[ "$checks" == *"block"* ]] ; then

	for app in "${apps[@]}" ; do
		IFS=$'\n'
		loggedInUser=$( /bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root )
		
		appfound=$( /usr/bin/find /Applications -maxdepth 3 -iname "$app" )
		
		if [[ -e /Users/"$loggedInUser"/Applications/ ]] ; then
			userappfound=$( /usr/bin/find /Users/"$loggedInUser"/Applications/ -maxdepth 3 -iname "$app" )
		fi
		
# 		altpathsfound=""
		for altpath in "${altpaths[@]}" ; do
			
			if [[ "$altpath" == "~"* ]] ; then 
				altpathshort=$( echo "$altpath" | cut -c 2- )
				altuserpath="/Users/${loggedInUser}${altpathshort}"
				
				if [[ -e "$altuserpath" ]] ; then 
				foundappinalthpath=$( /usr/bin/find "$altuserpath" -maxdepth 3 -iname "$app" )
				fi
			else
				if [[ -e "$altpath" ]] ; then		
					foundappinalthpath=$( /usr/bin/find "$altpath" -maxdepth 3 -iname "$app" )
				fi
			fi
			
			
			
			if [[ "$foundappinalthpath" != "" ]] ; then 
				altpathsfound+=("${foundappinalthpath}")
				logInUEX4DebugMode "Application $app was found in $altpath"
			else
				logInUEX4DebugMode "Application $app not found in $altpath"
			fi
		done
		
		
		if  [ "$appfound" != "" ] || [[ "$userappfound" != "" ]] || [[ "${altpathsfound[*]}" != "" ]] ; then
			appsinstalled+=("${app}")
		else 
			logInUEX4DebugMode "Applicaiton not found in any specified paths."
		fi
	done

	##replaced with new method
	# if [[ "${#apps[@]}" -le 4 ]] ; then
	# 	##testing for shellcheck
	# 	# apps4dialog=$( IFS=$'\n'; echo "${apps[*]}" | sed 's/.\{4\}$//' )
	# 	apps4dialog=$( IFS=$'\n'; echo "${apps[*]//.app/}")
	# else
	# 	##testing for shellcheck
	# 	# apps4dialog=$( IFS=$'\n'; printf "%-35s\t||\t%-35s\n $( echo "${apps[*]}" | sed 's/.\{4\}$//')" )
	# 	apps4dialog=$( IFS=$'\n'; printf "%-35s\t||\t%-35s\n ${apps[*]//.app/}" )
	# fi
	
fi



##########################################################################################
##							Pre-Processing Paramaters (pkg2install)						##
##########################################################################################

pathtopkg="$waitingRoomDIR"

# Notes
# The Variable for the whole list of applications is ${apps[@]}
##########################################################################################


##########################################################################################
## 									 No Apps to be blocked								##
##########################################################################################


if [[ "$checks" == *"block"* ]] && [[ "${appsinstalled[*]}" == "" ]] ; then 
	# original_string='i love Suzi and Marry'
	# string_to_replace_Suzi_with=Sara
	# result_string="${original_string/Suzi/$string_to_replace_Suzi_with}"
	log4_JSS "No apps are installed so change the block to a quit"
	checks="${checks/block/quit}"
fi

##########################################################################################
## 									Quit Application Processing							##
##########################################################################################

#Generate list of apps that are running that need to be quit
fn_generatateApps2quit

##replaced with new method
# Create dialog list with each item on a new line for the dialog windows
# If the list is too long then put two on a line separated by ||
# if [[ "$checks" == *"quit"* ]] ; then
# 	if [[ "${#apps2quit[@]}" -le 4 ]] ; then
# 		## testing for shellcheck
# 		# apps4dialog=$( IFS=$'\n'; echo "${apps2quit[*]}" | sed 's/.\{4\}$//' )
# 		apps4dialog=$( IFS=$'\n'; echo "${apps2quit[*]//.app/}" )
# 	else
# 		## testing for shellcheck
# 		# apps4dialog=$( IFS=$'\n'; printf '%-35s\t||\t%-35s\n' $( echo "${apps2quit[*]}" | sed 's/.\{4\}$//') )
# 		apps4dialog=$( IFS=$'\n'; printf "%-35s\t||\t%-35s\n ${apps2quit[*]//.app/}"  )
# 	fi
# fi

# modify lists for quitting and removing apps from lists
for app2quit in "${apps2quit[@]}" ; do
	delete_me=$app2quit
	for i in "${!appsinstalled[@]}" ; do
		if [[ "${appsinstalled[$i]}" == "$delete_me" ]] ; then
			unset "appsinstalled[$i]"
		fi 
	done
done

# modify lists for quitting and removing apps from lists
for app2reopen in "${apps2ReOpen[@]}" ; do
	delete_me=$app2reopen
	for i in "${!appsinstalled[@]}" ; do
		if [[ "${appsinstalled[$i]}" == "$delete_me" ]] ; then
			unset "appsinstalled[$i]"
		fi 
	done
done

# apps4dialogquit=$( IFS=$'\n'; printf '• Quit %s\n' $( echo "${apps[*]}" | sed 's/.\{4\}$//') )

## Testing ShellCheck
# apps4dialogquit=$( IFS=$'\n'; printf '%-25s\t%-25s\n' $( echo "${apps2quit[*]}" | sed 's/.\{4\}$//') )
# apps4dialogreopen=$( IFS=$'\n'; printf '%-25s\t%-25s\n' $( echo "${apps2ReOpen[*]}" | sed 's/.\{4\}$//') )
# apps4dialogblock=$( IFS=$'\n'; printf '%-25s\t%-25s\n' $( echo "${appsinstalled[*]}" | sed 's/.\{4\}$//') )

# shellcheck disable=SC2183
# shellcheck disable=SC2086
apps4dialogquit=$( IFS=$'\n'; printf '%-25s\t%-25s\n' ${apps2quit[*]//.app/} )
# shellcheck disable=SC2183
# shellcheck disable=SC2086
apps4dialogreopen=$( IFS=$'\n'; printf '%-25s\t%-25s\n' ${apps2ReOpen[*]//.app/} )
# shellcheck disable=SC2183
# shellcheck disable=SC2086
apps4dialogblock=$( IFS=$'\n'; printf '%-25s\t%-25s\n' ${appsinstalled[*]//.app/} )
unset IFS
##########################################################################################
## 									Logout and restart Processing						##
##########################################################################################


if [[ "$checks" == *"quit"* ]] && [[ "$checks" == *"logout"* ]] && [[ "${apps2quit[*]}" == "" ]] && [[ "${apps2ReOpen[*]}" == "" ]] ; then
	logInUEX " None of the apps are running that would need to be quit. Switching to logout only."
	checks="${checks/quit/}"
fi


if [[ "$checks" == *"quit"* ]] && [[ "$checks" == *"restart"* ]] && [[ "${apps2quit[*]}" == "" ]] && [[ "${apps2ReOpen[*]}" == "" ]] ; then
	logInUEX " None of the apps are running that would need to be quit. Switching to restart only."
	checks="${checks/quit/}"
fi

##########################################################################################
##							Check for pending Restarts or Logouts						##
##########################################################################################
fn_check4PendingRestartsOrLogout
if [[ "$restartQueued" == true ]] && [[ "$checks" == *"restart"* ]] ; then
	log4_JSS "Other restarts are queued"
fi

if [[ "$restartQueued" == true ]] && [[ "$checks" == *"logout"* ]] ; then
	log4_JSS "There are restarts are queued"
fi

if [[ "$logoutQueued" = true ]] && [[ "$checks" == *"logout"* ]] ; then
	log4_JSS "Other logouts are queued"
fi

# if there are no apps to quit/block and a logout or restart is already queued 
# if the user has a restart or log out pending and there is a quit/block there then change the restart/logout message 

# safety checks for suspackage && macOS Upgrade since it queues an immediate rebooted
if [[ "$checks" == *"suspackage"* ]] && [[ "$checks" == *"restart"* ]] && [[ "$restartQueued" == true ]] || [[ "$checks" == *"macosupgrade"* ]] && [[ "$checks" == *"restart"* ]] && [[ "$restartQueued" == true ]] ; then
	log4_JSS "Overwriting preApprovedInstall for $checks"
	preApprovedInstall=false
else
	if [[ "$restartQueued" == true ]] && [[ "$checks" == *"restart"* ]] && [[ "$checks" != *"quit"* ]] && [[ "$checks" != *"block"* ]] && [[ "$checks" != *"logout"* ]] && [[ "$checks" != *"power"* ]] && [[ "$checks" != *"lockmac"* ]] && [[ "$checks" != *"loginwindow"* ]] && [[ "$checks" != *"saveallwork"* ]] ; then
		log4_JSS "If install is only a restart requirement the user has already approved a restart previously in this session"
		preApprovedInstall=true
	elif [ "$logoutQueued" = true ] && [[ "$checks" == *"logout"* ]] && [[ "$checks" != *"restart"* ]] && [[ "$checks" != *"quit"* ]] && [[ "$checks" != *"block"* ]]  && [[ "$checks" != *"power"* ]] && [[ "$checks" != *"lockmac"* ]] && [[ "$checks" != *"loginwindow"* ]] && [[ "$checks" != *"saveallwork"* ]] ; then
		log4_JSS "If install is only a logout requirement the user has already approved a logout previously in this session"
		preApprovedInstall=true
	elif [[ "$checks" == *"logout"* ]] && [[ "$restartQueued" == true ]] && [[ "$checks" != *"quit"* ]] && [[ "$checks" != *"block"* ]]  && [[ "$checks" != *"power"* ]] && [[ "$checks" != *"lockmac"* ]] && [[ "$checks" != *"loginwindow"* ]] && [[ "$checks" != *"saveallwork"* ]] ; then
		log4_JSS "If install is only a logout requirement the user has already approved a restart previously in this session"
		preApprovedInstall=true
	elif [[ $restartQueued = true ]] && [[ "$checks" == *"restart"* ]] && [[ "$checks" == *"power"* ]] && [[ "$( fn_BatteryStatus )" == *"AC"* ]] &&  [[ "$checks" != *"quit"* ]] && [[ "$checks" != *"block"* ]] && [[ "$checks" != *"logout"* ]] && [[ "$checks" != *"power"* ]] && [[ "$checks" != *"lockmac"* ]] && [[ "$checks" != *"loginwindow"* ]] && [[ "$checks" != *"saveallwork"* ]] ;then
		log4_JSS "If install is only a restart requirement with a power requiremnet but power is connected and the the user has already approved a restart previously in this session"
		preApprovedInstall=true
	elif [[ "$restartQueued" == true ]] && [[ "$checks" == *"quit"* ]] && [[ "${apps2quit[*]}" == "" ]] && [[ "${apps2ReOpen[*]}" == "" ]] && [[ "$checks" != *"logout"* ]] && [[ "$checks" == *"power"* ]] && [[ "$( fn_BatteryStatus )" == *"AC"* ]] && [[ "$checks" != *"lockmac"* ]] && [[ "$checks" != *"loginwindow"* ]] && [[ "$checks" != *"saveallwork"* ]]  ; then
		log4_JSS "if the install has a quit and restart requirement with power required and conencted. Also, none of apps are running that need to be quit and the user has already approved a restart previously in this session"
		preApprovedInstall=true
	elif [[ "$restartQueued" == true ]] && [[ "$checks" == *"quit"* ]] && [[ "${apps2quit[*]}" == "" ]] && [[ "${apps2ReOpen[*]}" == "" ]] && [[ "$checks" != *"logout"* ]] && [[ "$checks" != *"power"* ]] && [[ "$checks" != *"lockmac"* ]] && [[ "$checks" != *"loginwindow"* ]] && [[ "$checks" != *"saveallwork"* ]]  ; then
		log4_JSS "if the install has a quit and restart requirement but none of apps are running that need to be quit and the user has already approved a restart previously in this session"
		preApprovedInstall=true
	elif [[ "$restartQueued" == true ]] && [[ "$checks" == *"logout"* ]] && [[ "${apps2quit[*]}" == "" ]] && [[ "${apps2ReOpen[*]}" == "" ]] && [[ "$checks" != *"power"* ]] && [[ "$checks" != *"lockmac"* ]] && [[ "$checks" != *"loginwindow"* ]] && [[ "$checks" != *"saveallwork"* ]]  ; then
		log4_JSS "if the install has a quit and logout requirement but none of apps are running that need to be quit and the user has already approved a logout previously in this session "
		preApprovedInstall=true
	elif [ "$logoutQueued" = true ] && [[ "$checks" == *"logout"* ]] && [[ "${apps2quit[*]}" == "" ]] && [[ "${apps2ReOpen[*]}" == "" ]] && [[ "$checks" != *"power"* ]] && [[ "$checks" != *"lockmac"* ]] && [[ "$checks" != *"loginwindow"* ]] && [[ "$checks" != *"saveallwork"* ]]  ; then
		log4_JSS "if the install has a quit and logout requirement but none of apps are running that need to be quit and the user has already approved a logout previously in this session "
		preApprovedInstall=true
	fi
fi #Suspackage && macOS upgrade safety net


##########################################################################################
## 									POSTPONE DIALOGS									##
##########################################################################################

#get the delay number form the plist or set it to zero

if [ -e "$UEXFolderPath"/defer_jss/"$uexNameConsolidated".plist ] ; then 
	# delayNumber=$( /usr/libexec/PlistBuddy -c "print delayNumber" "$UEXFolderPath"/defer_jss/"$uexNameConsolidated".plist 2>/dev/null )
	delayNumber=$(fn_getPlistValue "delayNumber" "defer_jss" "$uexNameConsolidated.plist")
else
	delayNumber=0
fi

if [[ $delayNumber == *"File Doesn"* ]] ; then delayNumber=0 ; fi

logInUEX4DebugMode "maxdefer is $maxdefer"
logInUEX4DebugMode "delayNumber is $delayNumber"

postponesLeft=$((maxdefer-delayNumber))

logInUEX4DebugMode "postponesLeft is $postponesLeft"

##########################################################################################
##									Disk Space Check									##
##########################################################################################
	

if [[ "$spaceRequired" ]] ; then

	diskCheckDelayNumber=$(fn_getPlistValue "diskCheckDelayNumber" "defer_jss" "$uexNameConsolidated.plist")
	log4_JSS "diskCheckDelayNumber is $diskCheckDelayNumber"

	if [[ -z "$diskCheckDelayNumber" ]] ; then
		diskCheckDelayNumber=0
	fi


	if [[ $diskCheckDelayNumber == *"File Doesn"* ]] ; then diskCheckDelayNumber=0 ; fi

	log4_JSS "diskCheckDelayNumber is $diskCheckDelayNumber"

	diskRemindersLeft=$((diskCheckDelaylimit-diskCheckDelayNumber))
	log4_JSS "diskRemindersLeft is $diskRemindersLeft"
	
	#####
	# Disk Space Check
	free=$( /usr/sbin/diskutil info / | grep "Free Space" )
	if [ -z "$free" ] ; then
		free=$( /usr/sbin/diskutil info / | grep "Available" | awk '{print $4}' )
		unit=$( /usr/sbin/diskutil info / | grep "Available" | awk '{print $5}' )
	else
		free=$( /usr/sbin/diskutil info / | grep "Free Space" | awk '{print $4}' )
		unit=$( /usr/sbin/diskutil info / | grep "Free Space" | awk '{print $5}' )
	fi

	space=${free%.*}

	if [[ "$unit" == GB ]] ; then
		convertedfree=$space
	elif [[ "$unit" == MB ]] ; then
		convertedfree=0
	elif [[ "$unit" == TB ]] ; then
		convertedfree=$((space * 1000))
	fi

	if [[ "$convertedfree" -lt "$spaceRequired" ]] ; then
		insufficientSpace=true
		remaining=$( echo "$spaceRequired" - "$convertedfree" | bc )
		log4_JSS "The computer has insufficient space."
		log4_JSS "Free in GB: $convertedfree"
		log4_JSS "Required in GB: $spaceRequired"
		log4_JSS "Space needed in GB: $remaining"
	else
		insufficientSpace=false
	fi

fi # is there is a space requirement

####

#########################################################################################
##					 		PACKAGE CHECK FOR DEPLOYED SOFWARE							##
##########################################################################################

fn_check4Packages ""

if [[ $packageMissing = true ]] && [[ $selfservicePackage != true ]] && [[ $insufficientSpace != true ]] ; then
	logInUEX4DebugMode "not selfservice" 
	fn_trigger "$UEXcachingTrigger"
	sleep 5
	
	fn_check4Packages ""
	# echo $packageMissing

	if [[ $packageMissing = true ]] ; then
		logInUEX4DebugMode "packageMissing is true"
		badvariable=true
	fi
fi

##########################################################################################
##							Automatic Detection of updatesfiltered 						##
##########################################################################################

if [[ "$suspackage" != true ]] && [[ "$checks" != *"uninstall"* ]] && [[ "$checks" != *"msupdate"* ]] ; then
	fn_checkPKGsForApps
fi


##########################################################################################
##								Setting heading and verbs								##
##########################################################################################
if [[ "$checks" == *"install"* ]] && [[ "$checks" != *"uninstall"* ]] ; then
	action="install"
	actioncap="Install"
	actioning="installing"
	actionation="Installation"
elif [[ "$checks" == *"update"* ]] ; then
	action="update"
	actioncap="Update"
	actioning="updating"
	actionation="Updates"
elif [[ "$checks" == *"uninstall"* ]] ; then
	action="uninstall"
	actioncap="Uninstall"
	actioning="uninstalling"
	actionation="Removal"
else
	action="install"
	actioncap="Install"
	actioning="installing"
	actionation="Installation"
fi


##########################################################################################
## 							BUILDING DIALOGS FOR POSTPONE								##
##########################################################################################
if [[ "$checks" == *"install"* ]] && [[ "$checks" != *"uninstall"* ]] ; then
	heading="Installing $AppName"
	action="install"
elif [[ "$checks" == *"update"* ]] ; then
	heading="Updating $AppName"
	action="update"
elif [[ "$checks" == *"uninstall"* ]] ; then
	heading="Uninstalling $AppName $AppVersion"
	action="uninstall"
else
	heading="$AppName"
	action="install"
fi

if [[ "$checks" == *"critical"* ]] || [[ "$checks" == *"compliance"* ]] ; then
	PostponeMsg+="This is a critical $action.
"
fi

if [ "$customMessage" ] ; then
	PostponeMsg+="
$customMessage
"
fi


if [[ $installDuration -gt 10 ]] ; then
	PostponeMsg+="This $action may take about $installDuration minutes.
"
fi

if [[ "$checks" == *"quit"* ]] && [[ "${apps2quit[*]}" == *".app"*  ]] || [[ "$checks" == *"saveallwork"* ]] || [[ "${apps2ReOpen[*]}" ]]  ; then
	PostponeMsg+="Before the $action starts:
"
elif [[ "$Laptop" ]] && [[ "$checks" == *"power"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="Before the $action starts:
" 
fi

if [[ "$Laptop" ]] && [[ "$checks" == *"power"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="• Connect to a charger
"
fi

if [[ "$checks" == *"saveallwork"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="• Save all work and close all apps.
"
fi


if [[ "$checks" != *"nopreclose"* ]] ; then
	quittingDesc="Apps will be safely quit"
else
	quittingDesc="Please quit"
fi


if [[ "${apps2quit[*]}" == *".app"*  ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="• $quittingDesc:
$apps4dialogquit

"
fi


if [[ "${apps2quit[*]}" == *".app"*  ]] && [[ "$checks" != *"custom"* ]] && [[ "${apps2ReOpen[*]}" ]] && [[ "$checks" == *"restart"* ]] ;then
	PostponeMsg+="$apps4dialogreopen
"
elif [[ "${apps2quit[*]}" == *".app"* ]] && [[ "$checks" != *"custom"* ]] && [[ "${apps2ReOpen[*]}" ]] && [[ "$checks" == *"logout"* ]] ; then
	PostponeMsg+="$apps4dialogreopen
"
elif [[ "${apps2ReOpen[*]}" ]] && [[ "$checks" == *"restart"* ]] && [[ "$checks" != *"custom"* ]] ;then
	PostponeMsg+="• $quittingDesc:
$apps4dialogreopen

"
elif [[ "${apps2ReOpen[*]}" ]] && [[ "$checks" == *"logout"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="• $quittingDesc:
$apps4dialogreopen

"
elif [[ "${apps2ReOpen[*]}" ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="• Apps will quit then reopen after:
$apps4dialogreopen

"
fi


# if [[ "${appsinstalled[*]}" == *".app"* ]] && [[ "$checks" == *"block"* ]] && [[ "$checks" != *"custom"* ]] ; then
# 	PostponeMsg+="• During the $action, do not open:
# $apps4dialogblock

# "
if [[ "${apps2ReOpen[*]}" ]] && [[ "${appsinstalled[*]}" != *".app"* ]] && [[ "$checks" == *"block"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="• During the $action, do not open them.

"
elif [[ "${apps2quit[*]}" == *".app"* ]] && [[ "${appsinstalled[*]}" != *".app"* ]] && [[ "$checks" == *"block"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="• During the $action, do not re-open them.

"
elif [[ "${apps2ReOpen[*]}" ]] && [[ "${appsinstalled[*]}" == *".app"* ]] && [[ "$checks" == *"block"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="• During the $action, do not re-open them, or:
$apps4dialogblock

"
elif [[ "${apps2quit[*]}" == *".app"* ]] && [[ "${appsinstalled[*]}" == *".app"* ]] && [[ "$checks" == *"block"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="• During the $action, do not re-open them, or:
$apps4dialogblock

"
elif [[ "${appsinstalled[*]}" == *".app"* ]] && [[ "$checks" == *"block"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="• During the $action, do not open:
$apps4dialogblock

"

fi

if [[ "$checks" == *"power"* ]] && [[ "$checks" != *"block"* ]] && [[ "$checks" != *"quit"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="
"
fi

if [[ "$checks" == *"restart"* ]] && [[ "$restartQueued" == true ]] && [[ "$checks" != *"custom"* ]] && [[ "$checks" != *"suspackage"* ]] && [[ "$checks" != *"macosupgrade"* ]] ; then
	PostponeMsg+="Please note:
"
elif [[ "$checks" == *"logout"* ]] && [ "$logoutQueued" = true ] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="Please note:
"
elif [[ "$checks" == *"restart"* ]] && [[ "$checks" != *"custom"* ]] && [[ "$checks" != *"suspackage"* ]] && [[ "$checks" != *"macosupgrade"* ]] ; then 
	PostponeMsg+="After the $action completes:
"
elif [[ "$checks" == *"logout"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="After the $action completes:
"
fi

echo ""***CHECK HERE**""

if [[ "$checks" == *"macosupgrade"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="After the preparation completes:
"
fi

if [[ "$checks" == *"macosupgrade"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="• Your computer will restart automatically.
"
fi

if [[ "$checks" == *"suspackage"* ]] && [[ "$checks" == *"restart"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="After the preparation completes:
"
fi

if [[ "$checks" == *"suspackage"* ]] && [[ "$checks" == *"restart"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="• Your computer will restart automatically.
"
fi

if [[ "$checks" == *"restart"* ]] && [[ "$checks" != *"custom"* ]] && [[ "$restartQueued" == true ]] && [[ "$checks" != *"suspackage"* ]] && [[ "$checks" != *"macosupgrade"* ]] ;then
PostponeMsg+="• You have a pending restart within 1 hour.
"
elif [[ "$checks" == *"restart"* ]] && [[ "$checks" != *"custom"* ]] && [[ "$checks" != *"suspackage"* ]] && [[ "$checks" != *"macosupgrade"* ]] ; then
	PostponeMsg+="• You will need to restart within 1 hour.
"
fi

if [[ "$checks" == *"logout"* ]] && [[ "$checks" != *"custom"* ]] && [[ "$restartQueued" == true ]] ; then
PostponeMsg+="• You have a pending restart within 1 hour.
"
elif [[ "$checks" == *"logout"* ]] && [[ "$checks" != *"custom"* ]] && [ "$logoutQueued" = true ] ; then
	PostponeMsg+="• You have a pending logout within 1 hour.
"
elif [[ "$checks" == *"logout"* ]] && [[ "$checks" != *"custom"* ]] ; then
	PostponeMsg+="• You will need to logout within 1 hour.
"
fi

if [[ $selfservicePackage != true ]] && [[ "$checks" != *"critical"* ]] && [[ $delayNumber -lt $maxdefer ]] ; then

	if [[ "$checks" == *"restart"* ]] || [[ "$checks" == *"logout"* ]] || [[ "$checks" == *"macosupgrade"* ]] || [[ "$checks" == *"loginwindow"* ]] || [[ "$checks" == *"lockmac"* ]] || [[ "$checks" == *"saveallworks"* ]] ; then
		PostponeMsg+="
To run during a break or end of day, click 'at Logout'."
	fi

if [[ $postponesLeft -gt 1 ]] ; then
	PostponeMsg+="
Start now or select a reminder. You may delay $postponesLeft more times.
"
else # no postpones available
	PostponeMsg+="
Start now or select a reminder. You may delay $postponesLeft more time.
"
fi # more than on 

fi #selfservice is not true

if [[ "$selfservicePackage" = true ]] ; then
	PostponeMsg+="
You can decide to 'Start now' or 'Cancel'.
"
fi

PostponeMsg+="
				
				
				
				
				
				
				
				
"


if [[ -e "$SelfServiceIcon" ]] ; then
	ssicon="$SelfServiceIcon"
else
	ssicon="/Applications/Self Service.app/Contents/Resources/Self Service.icns"
fi

SelfServiceAppPath=$( /usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf self_service_app_path 2>/dev/null)
SelfServiceAppName=$( echo "$SelfServiceAppPath" | /usr/bin/sed -ne 's|^.*/\(.*\).app$|\1|p' )

SelfServiceAppFolder="$( dirname "$SelfServiceAppPath" )"

if [[ -z "${SelfServiceAppName}" ]] ; then
	SelfServiceAppName="Self Service"
fi

SelfServiceAppNameDockPlist=$( /bin/echo "${SelfServiceAppName// /"%20"}" )
SelfServersioninDock=$( sudo -u "$loggedInUser" -H defaults read com.apple.Dock | grep "$SelfServiceAppNameDockPlist" )

# dynamically detect the location of where the user can find self service and update the dialog
if [[ "$SelfServersioninDock" ]] ; then
	SSLocation="your Dock or $SelfServiceAppFolder,"
else
	SSLocation="$SelfServiceAppFolder"
fi

selfservicerunoption="Open up $SelfServiceAppName from $SSLocation and start the $action of $AppName at any time.

Otherwise you will be reminded about the $action automatically after your chosen interval."

##########################################################################################
##								Insufficient Space Notification							##
##########################################################################################


if [[ "$checks" == *"critical"* ]] ; then
	spaceMsg+="This is a critical $action.
"
fi

spaceMsg+="Currently your computer does not have enough disk space to complete the $action. Please clear $remaining GB from your computer.
"

if [[ $selfservicePackage != true ]] && [[ $diskCheckDelayNumber -lt $diskCheckDelaylimit ]] ; then
	#statements
	spaceMsg+="
You'll be reminded about this $action again tomorrow after 9am.
"
elif [[ $selfservicePackage != true ]] && [[ "$checks" == *"helpticket"* ]] && [[ $diskCheckDelayNumber -ge $diskCheckDelaylimit ]] ; then
	#statements
	spaceMsg+="
$ServiceDeskName has been notified that you have not cleared the data and will be contacting you. You'll also be reminded about this $action again tomorrow after 9am.
"
	
	log4_JSS "User's exhausted time to clear space."
	log4_JSS "Kicking off process for notifying $ServiceDeskName."
	# used if theres a trigger to run to get tickets create
	if [[ $helpTicketsEnabledViaTrigger = true ]] ; then
		log4_JSS "Running Trigger $UEXhelpticketTrigger"
		triggerNgo "$UEXhelpticketTrigger"
	fi

	#used if a custom function has been added to clear the disk space
	if [[ $helpTicketsEnabledViaFunction = true ]] ; then
		log4_JSS "Running special function to create ticket"
		fn_create_help_desk_ticket
	fi

	# use to open the app that triggers the restricted software ... TeeHee, EVIL!
	if [[ $helpTicketsEnabledViaAppRestriction = true ]] ; then
		log4_JSS "Opening $restrictedAppName"
		sudo -u "$loggedInUser" -H open -ja "$restrictedAppName"
	fi

fi # if not  a self sef service run and not crtical and with enough delays lefft for the disk reminder

if [[ $selfservicePackage != true ]] && [[ $diskCheckDelayNumber -lt $diskCheckDelaylimit ]] && [[ "$checks" == *"helpticket"* ]] ; then

if [[ $diskRemindersLeft -gt 1 ]] ; then
	spaceMsg+="
You have $diskRemindersLeft more attempts left to clear up the space.
"
else # no postpones available
	spaceMsg+="
You have $diskRemindersLeft more attempt left to clear up the space.
"
fi

fi

if [[ "$selfservicePackage" = true ]] || [[ "$checks" == *"ssavail"* ]] ; then
	spaceMsg+="
You can also run the $action from $SelfServiceAppName when you've cleared up the space.
"
fi 


if [[ "$osMajor" -ge 12 ]] ; then
	spaceMsg+="
Use 'Find Clutter' to find large files or change your settings to save space."
fi

spaceMsg+="
				
				
				
				
				
				
				
				
"

##########################################################################################
##								INSTALL LOGOUT MESSAGE SETTING							##
##########################################################################################
# notice about needing charger connect if you want to install at logout
loggedInUser=$( /bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root )
usernamefriendly=$( id -P "$loggedInUser" | awk -F: '{print $8}' )

logoutMessage="To start the $action:

"

if [[ "$checks" == *"power"* ]] && [[ "$Laptop" ]] ; then
	logoutMessage+="• Connect to a Charger
"
fi

logoutMessage+="• Open the (Apple) Menu
• Click 'Log Out $usernamefriendly...' 

You have until tomorrow, then you will prompted again about the $action."


##########################################################################################
##								CHARGER REQUIRED MESSAGE								##
##########################################################################################
battMessage="Please note that the $modelName must be connected to a charger for a successful $action. Please connect it now. 
"

if [[ "$postponesLeft" -gt 0 ]] || [[ "$checks" != *"critical"* ]] ; then
	battMessage+="
Click 'No Charger' if you do not have it with you."

elif [[ "$checks" != *"critical"* ]] && [[ $delayNumber -lt $maxdefer ]] ; then
	battMessage+="
Otherwise click OK and choose a delay time."
fi

battMessage+="
Thank you!"


##########################################################################################
##									TIME OPITIONS FOR DELAYS							##
##########################################################################################

if [ "$debug" = true ] ; then
	delayOptions="0, 60, 3600, 7200, 14400, 86400"
else
	delayOptions="0, 3600, 7200, 14400, 86400"
fi


##########################################################################################
## 							Login Check Run if no on is logged in						##
##########################################################################################
# no login  RUN NOW
# (skip to install stage)
loggedInUser=$( /bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root )
## This is needed to get the exact proccess
# shellcheck disable=SC2009
logoutHookRunning=$( ps aux | grep "JAMF/ManagementFrameworkScripts/logouthook.sh" | grep -v grep )
log4_JSS "loggedInUser is $loggedInUser"

if [ "$logoutHookRunning" ] ; then 
	loggedInUser=""
fi

# if there is a Apple Setup Done File but the setup user is running assumge it's running migration assistanant and act as if there is no one logged in
# This will cause restart and long block installations to be put on a 1 hour delay automatically
if [[ "$loggedInUser" == "_mbsetupuser" ]] && [[ -f "$AppleSetupDoneFile" ]] ; then
	loggedInUser=""
	log4_JSS "Migration Assistant running, delaying restart and block installations by 1 hour"
fi

##########################################################################################
##										Postpone Stage									##
##########################################################################################

PostponeClickResult=""
skipNotices="false"

if [ -e "$UEXFolderPath"/defer_jss/"$uexNameConsolidated".plist ] ; then 

	delayNumber=$(fn_getPlistValue "delayNumber" "defer_jss" "$uexNameConsolidated.plist")
	presentationDelayNumber=$(fn_getPlistValue "presentationDelayNumber" "defer_jss" "$uexNameConsolidated.plist")
	inactivityDelay=$(fn_getPlistValue "inactivityDelay" "defer_jss" "$uexNameConsolidated.plist")

else
	delayNumber=0
	presentationDelayNumber=0
	inactivityDelay=0
fi

if [[ $delayNumber == *"File Doesn"* ]] ; then 
	delayNumber=0
	presentationDelayNumber=0
	inactivityDelay=0
fi

if [ -z $delayNumber ] ; then
	 delayNumber=0
fi

if [ -z $presentationDelayNumber ] ; then
	 presentationDelayNumber=0
fi

if [ -z $inactivityDelay ] ; then
	 inactivityDelay=0
fi


##########################################################################################
##									Login screen safety									##
##########################################################################################

loginscreeninstall=true

# if [[ "$checks" == *"power"* ]] &&  ; then 
# 	loginscreeninstall=false
# fi

if [[ $installDuration -ge 0 ]] && [[ "$checks" == *"restart"* ]] ; then
	loginscreeninstall=false
fi

if [[ $installDuration -ge 0 ]] && [[ "$checks" == *"notify"* ]] ; then
	loginscreeninstall=false
fi

if [[ $installDuration -ge 0 ]] && [[ "$checks" == *"macosupgrade"* ]] ; then
	loginscreeninstall=false
fi

if [[ $installDuration -ge 2 ]] && [[ "$checks" == *"block"* ]] ; then
	loginscreeninstall=false
fi



##########################################################################################
##										Login Check										##
##########################################################################################
fn_getLoggedinUser
if [[ "$loggedInUser" != root ]] ; then
# 	This is if for if a user is logged in


##########################################################################################
##									PRESENTATION DETECTION								##
##########################################################################################

presentationApps=(
"VidyoDesktop.app"
"Vidyo Desktop.app"
"People + Content IP.app"
)


fn_check4KeynoteRunningAndActiveInPresentationMode 

fn_check4PowerPointRunningInPresentationMode

fn_check4ActiveScreenSharingInSkypeForBusiness

fn_check4ActiveScreenSharingInMicrosoftTeams

fn_check4ScreenSharingSessionInWebExMeetingCenter

fn_check4ScreenSharingSessionInZoomUS

for app in "${presentationApps[@]}" ; do
	IFS=$'\n'
	## This is needed to get the parent proccess and prevent unwanted blocking
	# shellcheck disable=SC2009
	appid=$( ps aux | grep "$app/Contents/MacOS/" | grep -v grep | grep -v jamf | awk '{ print $2 }' )
	unset IFS
# 	echo Processing application $app
	if  [ "$appid" != "" ] ; then
		log4_JSS "Application $app is Running"
		presentationRunning=true
	fi
done




##########################################################################################
##								PRIMARY DIALOGS FOR INTERACTION							##
##########################################################################################
if [[ $presentationRunning != true ]] ; then
	fn_generatateApps2quit "beforedialog"
fi

reqlooper=1 
while [ $reqlooper = 1 ] ; do
	
	PostponeClickResultFile=/tmp/$UEXpolicyTrigger.txt
	echo > "$PostponeClickResultFile"
	
	jhTimeOut=1200 # keep the JH window on for 20 mins
	timeLimit=900 #15 mins
	
	if [[ $debug = true ]] ; then
		jhTimeOut=60 
		timeLimit=30
	fi
	
	if [[ "$insufficientSpace" = true ]] ; then

		if [[ "$osMajor" -ge 12 ]] ; then
			SpaceButton=$("$jhPath" -windowType hud -lockHUD -title "$title" -heading "$heading" -description "$spaceMsg" -button1 "OK" -button2 "Find Clutter" -icon "$diskicon" -timeout 600 -windowPosition center -timeout $jhTimeOut | grep -v 239 )
		else
			SpaceButton=$("$jhPath" -windowType hud -lockHUD -title "$title" -heading "$heading" -description "$spaceMsg" -button1 "OK" -icon "$diskicon" -timeout 600 -windowPosition center -timeout $jhTimeOut | grep -v 239 )
		fi

		if [[ "$SpaceButton" = "2" ]] ; then
			log4_JSS "User clicked the 'Find Clutter Button'"
			fn_find_Clutter
		fi
		echo 86400 > "$PostponeClickResultFile"
		PostponeClickResult=86400
		diskCheckDelayNumber=$((diskCheckDelayNumber+1))


		#Critical 
		# if [[ "$checks" == *"critical"* ]] && [[ "$diskCheckDelayNumber" -gt 1 ]] ; then
		# 	log4_JSS "Critical Install: User"
		# elif [[ "$selfservicePackage" = true ]] ; then 
		# 	#statements

		# else

		# fi




	elif [ $silentPackage = true ] ; then
		log4_JSS "Slient packge install deployment."
		echo 0 > "$PostponeClickResultFile"
		PostponeClickResult=0
		checks="${checks/quit/}"
		checks="${checks/block/}"
		checks="${checks/logout/}"
		skipNotices=true
		skipOver=true

	elif [[ $preApprovedInstall = true ]] ; then
		#statements
		log4_JSS "User has a previous approval for a restart of logout."
		echo 0 > "$PostponeClickResultFile"
		PostponeClickResult=0

	elif [ -z "${apps2quit[*]}" ] && [ -z "${apps2ReOpen[*]}" ] && [[ "$checks" == *"quit"* ]] && [[ "$checks" != *"restart"* ]] && [[ "$checks" != *"logout"* ]] && [[ "$checks" != *"notify"* ]] ; then
		log4_JSS "No apps need to be quit so $action can occur."
		echo 0 > "$PostponeClickResultFile"
		PostponeClickResult=0
		skipNotices=true
		# Only run presetation dely if the user is alllowed to postpone and has postponse avalable
		# this means that if they exhaust postpones its because they chose to and we only wiat a max of 3 hour for them to be try and delay after that presetaion delay is not possible
	elif [[ "$presentationRunning" = true ]] && [[ $presentationDelayNumber -lt 3 ]] && [[ $selfservicePackage != true ]] && [[ "$checks" != *"critical"* ]] && [[ $maxdefer -ge 1 ]] && [[ $delayNumber -lt $maxdefer ]] ; then
		echo 3600 > "$PostponeClickResultFile"
		PostponeClickResult=3600
		presentationDelayNumber=$((presentationDelayNumber+1))
		log4_JSS "Presentation running, delaying the install for 1 hour."
		# subtracting 1 so that thy don't get dinged for an auto delay
		delayNumber=$((delayNumber-1))
		skipNotices=true
		skipOver=true
		# if an presetation presentation is running and the max defer is 0 or critical then allow only one presentaion delay
	elif [[ "$presentationRunning" = true ]] && [[ $presentationDelayNumber -lt 1 ]] && [[ $selfservicePackage != true ]] && [[ $maxdefer = 0 ]] ; then
		echo 3600 > "$PostponeClickResultFile"
		PostponeClickResult=3600
		presentationDelayNumber=$((presentationDelayNumber+1))
		log4_JSS "Presentation running, delaying the install for 1 hour."
		# subtracting 1 so that thy don't get dinged for an auto delay
		delayNumber=$((delayNumber-1))
		skipNotices=true
		skipOver=true
	elif [[ "$presentationRunning" = true ]] && [[ $presentationDelayNumber -lt 1 ]] && [[ $selfservicePackage != true ]] && [[ "$checks" == *"critical"* ]] ; then
		echo 3600 > "$PostponeClickResultFile"
		PostponeClickResult=3600
		presentationDelayNumber=$((presentationDelayNumber+1))
		log4_JSS "Presentation running, delaying the install for 1 hour."
		# subtracting 1 so that thy don't get dinged for an auto delay
		delayNumber=$((delayNumber-1))
		skipNotices=true
		skipOver=true
		
	else
		logInUEX4DebugMode "Delay options are $delayOptions"
		# log4_JSS "Showing the $action window"
		if [[ "$checks" == *"critical"* ]] ; then
			log4_JSS "Showing the $action window. Critical"
			"$jhPath" -windowType hud -lockHUD -title "$title" -heading "$heading" -description "$PostponeMsg" -button1 "OK" -icon "$icon" -windowPosition center -timeout $jhTimeOut | grep -v 239 > "$PostponeClickResultFile" &
		
		else
			if [[ "$selfservicePackage" = true ]] ; then 
				"$jhPath" -windowType hud -lockHUD -title "$title" -heading "$heading" -description "$PostponeMsg" -button1 "Start now" -button2 "Cancel" -icon "$icon" -windowPosition center -timeout $jhTimeOut | grep -v 239 > "$PostponeClickResultFile" &
			else

				if [[ $delayNumber -ge $maxdefer ]] ; then 
					log4_JSS "Showing the $action window. No postpones left"
					"$jhPath" -windowType hud -lockHUD -title "$title" -heading "$heading" -description "$PostponeMsg" -button1 "OK" -icon "$icon" -windowPosition center -timeout $jhTimeOut | grep -v 239 > "$PostponeClickResultFile" &
				elif [[ "$checks" == *"restart"* ]] || [[ "$checks" == *"logout"* ]] || [[ "$checks" == *"macosupgrade"* ]] || [[ "$checks" == *"loginwindow"* ]] || [[ "$checks" == *"lockmac"* ]] || [[ "$checks" == *"saveallwork"* ]] ; then
					log4_JSS "Showing the $action window. Allowing for $action at logout. $postponesLeft postpones left"
					"$jhPath" -windowType hud -lockHUD -title "$title" -heading "$heading" -description "$PostponeMsg" -showDelayOptions "$delayOptions" -button1 "OK" -button2 "at Logout" -icon "$icon" -windowPosition center -timeout $jhTimeOut | grep -v 239 > "$PostponeClickResultFile" &
				else
					log4_JSS "Showing the $action window. $postponesLeft postpones left."
					"$jhPath" -windowType hud -lockHUD -title "$title" -heading "$heading" -description "$PostponeMsg" -showDelayOptions "$delayOptions" -button1 "OK" -icon "$icon" -windowPosition center -timeout $jhTimeOut | grep -v 239 > "$PostponeClickResultFile" &
				fi # Max defer exceeded
			fi # self service true

		fi # Critical install

	fi # if apps are empty & quit is set but no restart & no logout 

	# this is a safety net for closing and for 10.9 skiping jamfHelper windows
	counter=0
	jamfHelperOn=$( pgrep jamfHelper )
	while [[ "$jamfHelperOn" != "" ]] ; do
		counter=$((counter+1))
		sleep 1
	
		if [ "$counter" -ge $timeLimit ] ; then 
			killall jamfHelper
		fi

	##########################################################################################
	##						Detect a quit while the install window is open					##
	##########################################################################################
		
		if  [[ "$checks" == *"quit"* ]] && [[ "$checks" != *"restart"* ]] && [[ "$checks" != *"logout"* ]] && [[ $insufficientSpace != true ]] ; then
			# Start the function to kill jamfHelper and start the install if apps are quit
			fn_waitForApps2Quit

		elif [[ "$checks" == *"block"* ]] && [[ "${apps2ReOpen[*]}" == *".app"*  ]] && [[ "$checks" != *"restart"* ]] && [[ "$checks" != *"logout"* ]] && [[ $insufficientSpace != true ]] ; then
			# Start the function to kill jamfHelper and start the install if apps are quit
			fn_waitForApps2Quit
		fi

		jamfHelperOn=$( pgrep jamfHelper )
	done


	PostponeClickResult=$( cat "$PostponeClickResultFile" )
	# echo PostponeClickResult is $PostponeClickResult

	if [[ -z "$PostponeClickResult" ]] ; then

		# new safety override for not having the charger
		# BatteryTest=$( pmset -g batt )
		if [[ "$checks" == *"power"* ]] && [[ "$( fn_BatteryStatus )" != *"AC"* ]] ; then 
			if [ $inactivityDelay -ge 3 ] && [[ $delayNumber -ge $maxdefer ]] && [[ "$checks" == *"compliance"* ]] && [[ $insufficientSpace != true ]] ; then 
				log4_JSS "User has exhausted delay options and ignored the prompt 3 times further."
				log4_JSS "User does not have power connected and a power connection is required."
				log4_JSS "Unable to force install."
			fi
		# Check if the user has ignored the the install prompt and exhausted all delays
		else
			if [ $inactivityDelay -ge 3 ] && [[ $delayNumber -ge $maxdefer ]] && [[ "$checks" == *"compliance"* ]] && [[ $insufficientSpace != true ]] ; then 
				log4_JSS "User has exhausted delay options and ignored the prompt 3 times further."
				log4_JSS "This is a compliance policy and will be forced to install."
				forceInstall=true
			fi
		fi

		## compliance Checks are the only software titles that install without user choosing to install
		if [ "$forceInstall" = true ] && [[ "$checks" == *"compliance"* ]] ; then 
			PostponeClickResult=""
			if [[ "$checks" == *"restart"* ]] || [[ "$checks" == *"logout"* ]] ; then
				#statements
				checks+=" saveallwork"
			fi
		else
			log4_JSS "User was inactive on UEX Prompt or quit jamfHelper"
			if [[ $inactivityDelay -ge 3 ]] ; then 
					log4_JSS "User has ignored the prompt 3 times. Exhausting a deferral."
					PostponeClickResult=86400
					inactivityDelay=0
			else
				PostponeClickResult=6300
				delayNumber=$((delayNumber-1))
				inactivityDelay=$((inactivityDelay+1))
			fi
		fi
	else
		inactivityDelay=0
	fi


	logoutClickResult=""
	if [[ $PostponeClickResult == *2 ]] && [[ $selfservicePackage != true ]] ; then
		if [[ "$checks" == *"power"* ]] && [[ "$Laptop" ]] ; then
			logouticon="$baticon"
		else
			logouticon="$icon"
		fi

		log4_JSS "User chose to install at logout"

		logoutClickResult=$( "$jhPath" -windowType hud -lockHUD -icon "$logouticon" -title "$title" -heading "Install at logout" -description "$logoutMessage" -button1 "OK" -button2 "Go Back")
		if [[ $logoutClickResult = 0 ]] ; then 
			PostponeClickResult=86400
			loginscreeninstall=true
		else
			if [[ $logoutClickResult = 2 ]] ; then logInUEX "User cliked go back." ; fi
		fi
	fi

	if [[ $PostponeClickResult = "" ]] || [[ -z $PostponeClickResult ]] && [[ $forceInstall != true ]] ; then
		reqlooper=1
		skipOver=true
		log4_JSS "User either skipped or Jamf helper did not return a result."
	else # User chose an option
		skipOver=false
		## Exception required to get rid of last charcter
		# shellcheck disable=SC2001
		PostponeClickResult=$( echo $PostponeClickResult | sed 's/1$//' )
		if [[ "$PostponeClickResult" = 0 ]] ; then
			PostponeClickResult=""
		fi # ppcr=0

		# delayOptions="0, 60, 3600, 7200, 14400, 86400"
		if [[ "$PostponeClickResult" = 60 ]] ; then
			log4_JSS "Delay has been set to 1 minute"
		elif [[ "$PostponeClickResult" = 3600 ]] ; then
			log4_JSS "Delay has been set to 1 hour"
		elif [[ "$PostponeClickResult" = 7200 ]] ; then
			log4_JSS "Delay has been set to 2 hours"
		elif [[ "$PostponeClickResult" = 14400 ]] ; then
			log4_JSS "Delay has been set to 4 hours"
		elif [[ "$PostponeClickResult" = 86400 ]] && [ $loginscreeninstall != true ] ; then
			log4_JSS "Delay has been set to 1 day"
		fi


	fi # if PPCR is blank because the user clicked close

# If the install is 
if [[ $forceInstall = true ]] && [[ "$checks" == *"compliance"* ]] ; then
	#statements
	complianceDescription="This $action is required for compliance and security reasons. 

As it has been put off beyond the limit, this will now be installed automatically.

In the future, to avoid forceful interruptions please try to run this $action before you run out of postponements.

Thank you,
$jamfOpsTeamName"

	"$jhPath" -windowType hud -lockHUD -title "$title" -heading "Compliance $actionation - $heading" -description "$complianceDescription" -button1 "OK" -icon "$icon" -windowPosition lr -timeout 300 | grep -v 239 &
fi

	if [[ -n $PostponeClickResult ]] && [ $PostponeClickResult -gt 0 ] && [[ $selfservicePackage != true ]] && [[ "$ssavail" == true ]] && [[ "$skipOver" != true ]] && [[ $skipNotices != "true" ]] ; then
		"$jhPath" -windowType hud -title "$title" -heading "Start the $action anytime" -description "$selfservicerunoption" -showDelayOptions -timeout 20 -icon "$ssicon" -windowPosition lr | grep -v 239 & 
	fi



	##########################################################################################
	##									ARE YOU SURE SAFETY NET								##
	##########################################################################################
	#Generate list of apps that are running that need to be quit
	fn_generatateApps2quit

	## Testing Shellcheck
	# apps4dialogquit=$( IFS=$'\n'; printf '%-25s\t%-25s\n' $( echo "${apps2quit[*]}" | sed 's/.\{4\}$//') )
	# apps4dialogreopen=$( IFS=$'\n'; printf '%-25s\t%-25s\n' $( echo "${apps2ReOpen[*]}" | sed 's/.\{4\}$//') )
	
	# shellcheck disable=SC2183
	# shellcheck disable=SC2086
	apps4dialogquit=$( IFS=$'\n'; printf '%-25s\t%-25s\n' ${apps2quit[*]//.app/} )
	# shellcheck disable=SC2183
	# shellcheck disable=SC2086
	apps4dialogreopen=$( IFS=$'\n'; printf '%-25s\t%-25s\n' ${apps2ReOpen[*]//.app/} )
	unset IFS

	areyousureHeading="Please save your work"

	if [[ "$checks" == *"saveallwork"* ]] ; then
		areyousureMessage="Please save ALL your work before clicking continue."
	else # use for quigign spefic apps
		areyousureMessage="Please save your work before clicking continue.
These apps will be quit:
"
		areyousureMessage+="
$apps4dialogquit
$apps4dialogreopen
"
	fi #if save all work is set 
	
		areyousureMessage+="
Current work may be lost if you do not save before proceeding."

	areYouSure=""
	logInUEX "skipNotices is $skipNotices"
	if [[ "$skipNotices" != true ]] ; then
		if [[ "${apps2quit[*]}" == *".app"* ]] && [[ -z "$PostponeClickResult" ]] || [[ "${apps2ReOpen[*]}" == *".app"* ]] && [[ -z "$PostponeClickResult" ]] || [[ "$checks" == *"saveallwork"* ]] && [[ -z "$PostponeClickResult" ]] ; then
			

		#########################
		# 		SAFE Quit	 	#
		#########################


			fn_generatateApps2quit "safequit"
			# Safe quit options
			if [[ "${apps2kill[*]}" != "" ]] && [[ "$checks" != *"nopreclose"* ]] ; then

				# if the app to re launch is not blank it means the apps were quit manually when the install window was up
				if 	[[ -z "${apps2Relaunch[*]}" ]] ; then
					apps2Relaunch=()
				fi
				for app in "${apps2kill[@]}" ; do
					IFS=$'\n'
					## This is needed to get the parent proccess and prevent unwanted blocking
					# shellcheck disable=SC2009
					appid=$( ps aux | grep "$app"/Contents/MacOS/ | grep -v grep | grep -v jamf | awk '{ print $2 }' )
					# Processing application $app
						if  [[ $appid != "" ]] ; then
							# testing #36 for multiple quitting
							# for id in $appid; do
								# Application  $app is still running.
								# Killing $app. pid is $id 
								apps2Relaunch+=( "$app" )
								log4_JSS "Safe quitting $app"
								sudo -u "$loggedInUser" -H osascript -e "activate app \"$app\""
								sudo -u "$loggedInUser" -H osascript -e "quit app \"$app\""
							# done 
						fi
				done
				unset IFS
			fi
		fi

		sleep 2

		areYouSureClickResultFile=/tmp/areYouSure$UEXpolicyTrigger.txt
		
		fn_generatateApps2quit

		if [[ "${apps2quit[*]}" == *".app"* ]] && [[ -z "$PostponeClickResult" ]] || [[ "${apps2ReOpen[*]}" == *".app"* ]] && [[ -z "$PostponeClickResult" ]] || [[ "$checks" == *"saveallwork"* ]] && [[ -z "$PostponeClickResult" ]] ; then
			fn_generatateApps2quit "areyousure"
			# if [[ "$checks" == *"critical"* ]] || [[ $delayNumber -ge $maxdefer ]] ; then
			# 	areYouSure=$( "$jhPath" -windowType hud -lockHUD -icon "$icon" -title "$title" -heading "$areyousureHeading" -description "$areyousureMessage" -button1 "Continue" -timeout 300 -countdown)
			# else
			# 	areYouSure=$( "$jhPath" -windowType hud -lockHUD -icon "$icon" -title "$title" -heading "$areyousureHeading" -description "$areyousureMessage" -button1 "Continue" -button2 "Go Back" -timeout 600 -countdown)
			# fi
			rm "$areYouSureClickResultFile"
			showAreYouSureWindow=true
			if [[ "$checks" == *"critical"* ]] || [[ $delayNumber -ge $maxdefer ]] ; then
				"$jhPath" -windowType hud -lockHUD -icon "$icon" -title "$title" -heading "$areyousureHeading" -description "$areyousureMessage" -button1 "Continue" -timeout 300 -countdown > "$areYouSureClickResultFile" &
			else
				"$jhPath" -windowType hud -lockHUD -icon "$icon" -title "$title" -heading "$areyousureHeading" -description "$areyousureMessage" -button1 "Continue" -button2 "Go Back" -timeout 600 -countdown > "$areYouSureClickResultFile" &
			fi

			sleep 1

		fi # ARE YOU SURE? if apps are still running

		##only loop the are for an are you sure response if it's supposed to show
		if [[ "$showAreYouSureWindow" == true ]] ; then

			areYouSureLooper=0
			while [[ "$areYouSureLooper" = 0 ]] ; do
				#statements
				if [[ -e "$areYouSureClickResultFile" ]] ; then
					#statements
					areYouSure=$(cat "$areYouSureClickResultFile")

					# log4_JSS "areYouSure Button result was: $areYouSure"
					if [[ -z "$areYouSure" ]] ; then
						areYouSureLooper=0
					elif [[ "$areYouSure" = "2" ]] ; then
						reqlooper=1
						areYouSureLooper=1
						skipOver=true
					else
						reqlooper=0
						areYouSureLooper=1
						if [[ $areYouSure = 0 ]] ; then 
							log4_JSS "User Clicked continue or timer ran out on are you sure."
							areYouSureLooper=1
						fi
						if [[ $areYouSure = 239 ]] ; then 
							log4_JSS "User Quit are you sure jamfHelper."
							areYouSureLooper=1
						fi
					fi
				fi
				

				if  [[ "$checks" == *"quit"* ]] ; then
					# Start the function to kill jamfHelper and start the install if apps are quit
					fn_waitForApps2Quit4areYouSure

				elif [[ "$checks" == *"block"* ]] && [[ "${apps2ReOpen[*]}" == *".app"*  ]] ; then
					# Start the function to kill jamfHelper and start the install if apps are quit
					fn_waitForApps2Quit4areYouSure
				fi

			done

		fi ##only loop the are for an are you sure response if it's supposed to show

	fi #SkipOver is not true


	##########################################################################################
	##										BATTERY SAFETY NET	 							##
	##########################################################################################
	# BatteryTest=$( pmset -g batt )
	if [[ "$checks" == *"power"* ]] && [[ "$( fn_BatteryStatus )" != *"AC"* ]] && [[ -z $PostponeClickResult ]] && [[ "$skipOver" != true ]] ; then
		reqlooper=1
		# /bin/echo postponesLeft is "$postponesLeft"
		if [[ "$postponesLeft" -gt 0 ]] && [[ "$checks" != *"critical"* ]] ; then
			"$jhPath" -windowType hud -lockHUD -icon "$baticon" -title "$title" -heading "Charger Required" -description "$battMessage" -button1 "OK" -timeout 60 > /dev/null 2>&1 &
		else
			batteryClickResultFile="/private/tmp/batteryClickResult$UEXpolicyTrigger.txt"
			##clear the previous response 
			if [[ -f "$batteryClickResultFile" ]] ; then 
				/bin/rm "$batteryClickResultFile"
			fi
			"$jhPath" -windowType hud -lockHUD -icon "$baticon" -title "$title" -heading "Charger Required" -description "$battMessage" -button1 "No Charger" -timeout 60 > "$batteryClickResultFile" &
		fi



		batlooper=1
		jamfHelperOn=$( pgrep jamfHelper )
		while [ $batlooper = 1 ] && [[ $jamfHelperOn != "" ]] ; do
			# BatteryTest=$( pmset -g batt )
			jamfHelperOn=$( pgrep jamfHelper )
			# /bin/echo batteryClickResult is $batteryClickResult

			if [[ "$( fn_BatteryStatus )" != *"AC"* ]] && [[ "$checks" == *"critical"* ]] ; then 
				# charger still not connected
				batlooper=1 
				sleep 1
			elif [[ "$( fn_BatteryStatus )" != *"AC"* ]] ; then
				# charger still not connected
				batlooper=1 
				sleep 1
			else 
				batlooper=0
				killall jamfHelper
				logInUEX "AC power connected"
				sleep 1
			fi
		done

		##new Override for if the user doesn't have the charger available 
		if [[ -f "$batteryClickResultFile" ]] ; then
			batteryClickResult=$( cat "$batteryClickResultFile" )
			if [[ "$postponesLeft" -eq 0 ]] && [[ "$batteryClickResult" == 0 ]] ; then
				batlooper=0
				batteryOveride=true
				echo 3600 > "$PostponeClickResultFile"
				PostponeClickResult=3600
				killall jamfHelper
				log4_JSS "User does not have AC power available"
				sleep 1
			fi
		fi # check for battery click button


	elif [[ "$skipOver" != true ]] ; then 
		reqlooper=0
	fi # if power required and  on AC and PostPoneClickResult is Empty 

# 		echo checks $checks
# 		echo reqlooper $reqlooper
# 		echo logoutClickResult $logoutClickResult
# 		echo PostponeClickResult $PostponeClickResult
# 		echo skipOver $skipOver

	# BatteryTest=$( pmset -g batt )
	if [[ "$checks" == *"power"* ]] && [[ "$( fn_BatteryStatus )" != *"AC"* ]] && [[ -z $PostponeClickResult ]] && [[ "$batteryOveride" != true ]] ; then
		reqlooper=1
	else 
		if [[ $logoutClickResult == *"2" ]] ; then 
			reqlooper=1
		elif [[ -z $logoutClickResult ]] && [[ "$skipOver" != true ]] ; then 
			reqlooper=0
		elif [[ "$skipOver" != true ]] ; then
			reqlooper=0
		fi
	fi # power reqlooper change
	
done # reqlooper is on = 1 for logged in users
	
## Count up on Delay choice 
if [[ $PostponeClickResult -gt 0 ]] ; then
	# user chose to postpone so add number to postpone
	delayNumber=$((delayNumber+1))
fi
	
else # loginuser is null therefore no one is logged in and 

	logInUEX "No one is logged in"
	if [[ -a "$UEXFolderPath"/defer_jss/"$uexNameConsolidated".plist ]] ; then
		echo delay exists
		# installNow=$( /usr/libexec/PlistBuddy -c "print loginscreeninstall" "$UEXFolderPath"/defer_jss/"$uexNameConsolidated".plist 2>/dev/null )
		installNow=$(fn_getPlistValue "loginscreeninstall" "defer_jss" "$uexNameConsolidated.plist")
		echo "$installNow"
		if [[ $installNow == "true" ]] ; then 
			log4_JSS "Install at login permitted"
			# install at login permitted
			
			# BatteryTest=$( pmset -g batt )
			if [[ "$checks" == *"power"* ]] && [[ "$( fn_BatteryStatus )" != *"AC"* ]] ; then
				log4_JSS "Power not connected postponing 24 hours"
				echo power not connected postponing 24 hours
				delayNumber=$((delayNumber+0))
				PostponeClickResult=86400
			else
				log4_JSS "All requirements complete $actioning"
				# all requirements complete installing
# 				skipNotices="true"
				PostponeClickResult="" 
			fi
		
		else
		log4_JSS "Install at login NOT permitted"
		# install at login NOT permitted
			skipNotices="true"
			PostponeClickResult=3600
		 fi
		
	else
	
		skipNotices="true"
		
	
		if [[ $loginscreeninstall == false ]] ; then
			log4_JSS "First time running install but login screen install not permitted. Postponing for 1 hour."
			delayNumber=$((delayNumber+0))
			PostponeClickResult=3600
		fi
	fi
	
	
	
fi # No user is logged in


##########################################################################################
##										Postpone Stage									##
##########################################################################################

if [[ $PostponeClickResult -gt 0 ]] ; then
	
	
	if [[ $PostponeClickResult = 86400 ]] ; then
		# get the time tomorrow at 9am and delay until that time.
		tomorrow=$( date -v+1d )
		tomorrowTime=$( echo "$tomorrow" | awk '{ print $4}' )
		tomorrow9am="${tomorrow/$tomorrowTime/09:00:00}"
		tomorrow9amEpoch=$( date -j -f '%a %b %d %T %Z %Y' "$tomorrow9am" '+%s' )
		nowEpoch=$( date +%s )
		PostponeClickResult=$((tomorrow9amEpoch-nowEpoch))
	fi # if the postpone is 1 day
	
	# User chose postpone time
	delaytime=$PostponeClickResult
	logInUEX "Delay Time = $delaytime"
	
	# calculate time and date just before plist creation
	runDate=$( date +%s )
	runDate=$((runDate-300))
	runDateFriendly="$( date -r "$runDate" )"
		
	# Calculate the date that
	delayDate=$((runDate+delaytime))
	delayDateFriendly=$( date -r $delayDate )

	

	if [[ "$selfservicePackage" = true ]] ; then
		log4_JSS "SELF SERVICE PACKAGE: Skipping Delay Service"

		fn_check4Packages ""
		if [[ "$packageMissing" = true ]] && [[ "$insufficientSpace" != true ]] ; then
			triggerNgo "$UEXcachingTrigger"
		fi

	else # not a self service package

		log4_JSS "The next $action prompt is postponed until after $delayDateFriendly"
		
		# if the defer folder if empty and i'm creating the first deferal then invetory updates are needed to the comptuer is in scope of the deferral service
		## Need the plist as a file name in list format
		# shellcheck disable=SC2010
		deferfolderContents=$( ls "$UEXFolderPath"/defer_jss/| grep ".plist" )
		if [[ -z "$deferfolderContents" ]] ; then
			InventoryUpdateRequired=true
		fi
		
		if [[ -a "$UEXFolderPath"/defer_jss/"$uexNameConsolidated".plist ]] ; then
			# Create Plist with postpone properties 
			fn_setPlistValue "package" "$uexNameConsolidated" "defer_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "delayDate" "$delayDate" "defer_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "delayDateFriendly" "$delayDateFriendly" "defer_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "delayNumber" "$delayNumber" "defer_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "presentationDelayNumber" "$presentationDelayNumber" "defer_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "diskCheckDelayNumber" "$diskCheckDelayNumber" "defer_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "inactivityDelay" "$inactivityDelay" "defer_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "loginscreeninstall" "$loginscreeninstall" "defer_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "policyTrigger" "$UEXpolicyTrigger" "defer_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "checks" "$checks" "defer_jss" "$uexNameConsolidated.plist"

		else
			# Create Plist with postpone properties 
			fn_addPlistValue "uexNameConsolidated" "string" "$uexNameConsolidated" "defer_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "delayDate" "string" "$delayDate" "defer_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "delayDateFriendly" "string" "$delayDateFriendly" "defer_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "delayNumber" "string" "$delayNumber" "defer_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "presentationDelayNumber" "string" "$presentationDelayNumber" "defer_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "diskCheckDelayNumber" "string" "$diskCheckDelayNumber" "defer_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "inactivityDelay" "string" "$inactivityDelay" "defer_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "loginscreeninstall" "string" "$loginscreeninstall" "defer_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "policyTrigger" "string" "$UEXpolicyTrigger" "defer_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "checks" "string" "$checks" "defer_jss" "$uexNameConsolidated.plist"
		fi # if the defer plist exists 

	fi # if self service pacakge is true

fi # if there is a postponement

##########################################################################################
##									Installation Stage									##
##########################################################################################

# If no postpone time was set then start the install
if [[ $PostponeClickResult == "" ]] ; then

	log4_JSS "UEX actions for $actionation process starting."

	# 
	if [[ "$spaceRequired" ]] && [[ "$checks" == *"compliance"* ]] && [[ "$helpTicketsEnabledViaTrigger" = true ]] ; then
		log4_JSS "User has enough space for installation"
		triggerNgo "$ClearHelpTicketRequirementTrigger"
	fi

# Do not update invtory update if UEX is only being used for notificaitons
# if its an innstallation polciy then update invetory at the end
if [[ "$checks" != "notify" ]] || [[ "$checks" != "notify custom" ]] ; then
	InventoryUpdateRequired=true
fi



	###########################################
	# Downloading notice for selfservicePackage #
	###########################################
	fn_check4Packages ""

	if [[ $packageMissing = true ]] && [[ "$selfservicePackage" = true ]] && [[ $insufficientSpace != true ]] ; then
		status="$heading,
Downloading packages..."
		"$CocoaDialog" bubble --title "$title" --text "$status" --icon-file "$icon"

		fn_trigger "$UEXcachingTrigger"

		fn_check4Packages ""

		if [[ $packageMissing = true ]] ; then
			badvariable=true
		fi
	fi


	##########################
	# Install Started Notice #
	##########################

	if [[ $preApprovedInstall = true ]] && [[ "$loggedInUser" ]] && [[ $logoutQueued = true ]] && [[ $restartQueued != true ]] ;then
		status="$heading,
another $action is starting
You will be logged out after all software changes are complete."
		"$CocoaDialog" bubble --title "$title" --text "$status" --icon-file "$icon" --timeout 10
	elif [[ $preApprovedInstall = true ]] && [[ "$loggedInUser" ]] && [[ $restartQueued = true ]] ; then
		status="$heading,
another $action is starting
The restart will happpen after all software changes are complete."
		"$CocoaDialog" bubble --title "$title" --text "$status" --icon-file "$icon" --timeout 10
	fi


	if [[ "$selfservicePackage" = true ]] && [[ $preApprovedInstall != true ]] && [[ $skipNotices != "true" ]] || [[ $skipNotices != "true" ]] && [[ $preApprovedInstall != true ]]   ; then	
		status="$heading,
starting $action..."
		if [[ "$loggedInUser" ]] ; then 
			"$CocoaDialog" bubble --title "$title" --text "$status" --icon-file "$icon"
		else
			"$jhPath" -icon "$icon" -windowType hud -windowPosition lr -startlaunchd -title "$title" -description "$status" -timeout 5 > /dev/null 2>&1 
		fi
		logInUEX "Notified user $heading, starting $action... "
		
		if [[ -z "$loggedInUser" ]] ; then 
# 		"$jhPath" -icon "$icon" -windowType hud -windowPosition lr -startlaunchd -title "$title" -description "$status" -timeout 5 > /dev/null 2>&1 &

/bin/rm /Library/LaunchAgents/github.cubandave.UEX-jamfhelper.plist > /dev/null 2>&1 
cat <<EOT >> /Library/LaunchAgents/github.cubandave.UEX-jamfhelper.plist 
<?xml version="1.0" encoding="UTF-8"?> 
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> 
<plist version="1.0"> 
<dict> 
<key>Label</key> 
<string>github.cubandave.UEX-jamfhelper</string> 
<key>RunAtLoad</key> 
<true/> 
<key>LimitLoadToSessionType</key> 
<string>LoginWindow</string> 
<key>ProgramArguments</key> 
<array> 
<string>/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper</string> 
<string>-windowType</string> 
<string>hud</string> 
<string>-windowPosition</string> 
<string>lr</string> 
<string>-title</string> 
<string>"$title"</string> 
<string>-lockHUD</string> 
<string>-description</string> 
<string>$heading, $action is in progress please do not power off the computer.</string> 
<string>-icon</string> 
<string>"$icon"</string> 
</array> 
</dict> 
</plist>
EOT

chown root:wheel /Library/LaunchAgents/github.cubandave.UEX-jamfhelper.plist
chmod 644 /Library/LaunchAgents/github.cubandave.UEX-jamfhelper.plist

launchctl load /Library/LaunchAgents/github.cubandave.UEX-jamfhelper.plist

sleep 5
killall loginwindow > /dev/null 2>&1
sleep 1
rm /Library/LaunchAgents/github.cubandave.UEX-jamfhelper.plist

fi # no on logged in

	fi # skip notice is not true or is a self service install

##########################################################################################
##									STARTING ACTIONS									##
##########################################################################################

	#############################################
	# 		Quit & Blocking Actions Merged	 	#
	#############################################

	if [[ "$checks" == *"quit"* ]] || [[ "$checks" == *"block"* ]] ; then
	# Quit all the apps2quit that were running at the time of the notification 
		
		# Generate the list of apps still running that need to
		fn_generatateApps2quit

		if [[ "${apps2kill[*]}" != "" ]] ; then

			# if the app to relaunch is not blank it means the apps were quit manually when the install window was up
			if 	[[ -z "${apps2Relaunch[*]}" ]] ; then
				apps2Relaunch=()
			fi

			for app in "${apps2kill[@]}" ; do
				IFS=$'\n'
				
				## This is needed to get the parent proccess and prevent unwanted blocking
				# shellcheck disable=SC2009
				appid=$( ps aux | grep "$app"/Contents/MacOS/ | grep -v grep | grep -v jamf | awk '{ print $2 }' )
				# Processing application $app
					if  [[ $appid != "" ]] ; then
						
						#add to the relaunch list once
						#testing for #36
						apps2Relaunch+=( "$app" )
						
						for id in $appid; do
							# Application  $app is still running.
							# Killing $app. pid is $id 

							if [[ "$checks" == *"merp"* ]] ; then
								log4_JSS "Trying to safe quit $app to avoid Microsoft Error Reporting"
								sudo -u "$loggedInUser" -H osascript -e "activate app \"$app\""
								sudo -u "$loggedInUser" -H osascript -e "quit app \"$app\""
								sleep 2
							fi

							processstatus=$( ps -p "$id" )
							if [[ "$processstatus" == *"$app"* ]] ; then
								log4_JSS "$app is still running. Killing process id $id."
								# log4_JSS "Re-opening $app"
								# osascript -e "activate app \"$app\""
								# osascript -e "quit app \"$app\""
								kill "$id"
								sleep 1
							fi

							processstatus=$( ps -p "$id" )
							if [[ "$processstatus" == *"$app"* ]] ; then
								#statements
								log4_JSS "The process $id was still running for application $app. Force killing Application."
								kill -9 "$id"
							fi 
						done 
					fi
			done
			unset IFS
		fi
	fi

	#####################
	# 		Block	 	#
	#####################
	if [[ "$checks" == *"block"* ]] ; then	
		# calculate time and date just before plist creation
		runDate=$( date +%s )
		runDateFriendly="$( date -r "$runDate" )"
		
		# Create Plist with all that properties to block the apps
		# added Package & date info for restar safety measures
		fn_addPlistValue "name" "string" "$heading" "block_jss" "$uexNameConsolidated.plist"
		fn_addPlistValue "uexNameConsolidated" "string" "$uexNameConsolidated" "block_jss" "$uexNameConsolidated.plist"
		fn_addPlistValue "runDate" "string" "$runDate" "block_jss" "$uexNameConsolidated.plist"
		fn_addPlistValue "runDateFriendly" "string" "$runDateFriendly" "block_jss" "$uexNameConsolidated.plist"
		fn_addPlistValue "apps2block" "string" "$apps2block" "block_jss" "$uexNameConsolidated.plist"
		fn_addPlistValue "checks" "string" "$checks" "block_jss" "$uexNameConsolidated.plist"

		# Start the agent to actively block the applications
		logInUEX "Starting Blocking Service"
		triggerNgo uexblockagent

	
	fi # if the check has block

	#####################
	# 		Logout	 	#
	#####################

	if [[ "$checks" == *"logout"* ]] ; then
	echo script wants me to logout
		loggedInUser=$( /bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' )
		
		# calculate time and date just before plist creation
		runDate=$( date +%s )
		runDateFriendly="$( date -r "$runDate" )"
		
		# Testing
		# loggedInUser="cedarari"
		
		# Create plist with logout required 
		# added username and run time as safety measure to put in just in case
		# added checked variable to allow for clearring the plist so that the second stage can change it then delete it.
		
		if [[ -a "$UEXFolderPath"/logout_jss/"$uexNameConsolidated".plist ]] ; then
			fn_setPlistValue "name" "$heading" "logout_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "uexNameConsolidated" "$uexNameConsolidated" "logout_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "runDate" "$runDate" "logout_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "runDateFriendly" "$runDateFriendly" "logout_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "loggedInUser" "$loggedInUser" "logout_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "checked" "false" "logout_jss" "$uexNameConsolidated.plist"

		else
			fn_addPlistValue "name" "string" "$heading" "logout_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "uexNameConsolidated" "string" "$uexNameConsolidated" "logout_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "runDate" "string" "$runDate" "logout_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "runDateFriendly" "string" "$runDateFriendly" "logout_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "loggedInUser" "string" "$loggedInUser" "logout_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "checked" "bool" "false" "logout_jss" "$uexNameConsolidated.plist"


		fi


	fi # if the check has logout

	#####################
	# 		Restart	 	#
	#####################

	if [[ "$checks" == *"restart"* ]] ; then
		# calculate time and date just before plist creation
		runDate=$( date +%s )
		
		
		# Create plist with Restart required
		# Added date to allow for clearing and fail safe in case the user restart manually
		if [[ -a "$UEXFolderPath"/restart_jss/"$uexNameConsolidated".plist ]] ; then
			fn_setPlistValue "name" "$heading" "restart_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "uexNameConsolidated" "$uexNameConsolidated" "restart_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "runDate" "$runDate" "restart_jss" "$uexNameConsolidated.plist"
			fn_setPlistValue "runDateFriendly" "$runDateFriendly" "restart_jss" "$uexNameConsolidated.plist"

		else
			fn_addPlistValue "name" "string" "$heading" "restart_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "uexNameConsolidated" "string" "$uexNameConsolidated" "restart_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "runDate" "string" "$runDate" "restart_jss" "$uexNameConsolidated.plist"
			fn_addPlistValue "runDateFriendly" "string" "$runDateFriendly" "restart_jss" "$uexNameConsolidated.plist"
		fi # if the check has restart




	fi

	################
	# progress bar #
	################
	# echo skipNotices is $skipNotices
	pleaseWaitDaemon="/Library/LaunchDaemons/github.cubandave.UEX-PleaseWait.plist"
	if  [ $installDuration -ge 5 ] && [[ $skipNotices != "true" ]] && [[ $preApprovedInstall != true ]] ; then
	# only run the progress indicator if the duration is 5 minutes or longer 
		
		# load daemon to keep pleasewait application up for notification purposes
		logInUEX "Starting PleaseWait Application"

		if [[ -e "$pleaseWaitDaemon" ]] ; then
			rm "$pleaseWaitDaemon"
		fi 

cat <<EOT >> "$pleaseWaitDaemon"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Disabled</key>
	<false/>
	<key>EnvironmentVariables</key>
	<dict>
		<key>PATH</key>
		<string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/sbin</string>
	</dict>
	<key>KeepAlive</key>
	<dict>
		<key>SuccessfulExit</key>
		<true/>
	</dict>
	<key>Label</key>
	<string>github.cubandave.UEX-PleaseWait</string>
	<key>ProgramArguments</key>
	<array>
		<string>$PleaseWaitApp/Contents/MacOS/PleaseWait</string>
	</array>
	<key>RunAtLoad</key>
	<false/>
</dict>
</plist>
EOT

		chown root:wheel "$pleaseWaitDaemon"
		chmod 644 "$pleaseWaitDaemon"

		launchctl load -w "$pleaseWaitDaemon"
		launchctl start -w "$pleaseWaitDaemon"

		
		# Launch the service to cycle through apps or logout/restart requirement
		logInUEX "Running the pleasewait updater"
		triggerNgo PleaseWaitUpdater
		
		# Sets the Initial Values 
		echo "Installation in progress..." > "$pleasewaitPhase"
		echo "Please Wait..." > "$pleasewaitProgress"
		echo "100" > "$pleasewaitInstallProgress"
		
		# Sets the Initial Values 
		if [[ "$suspackage" = true ]] ; then
			echo "Software Updates in progress" > "$pleasewaitPhase"
			# chflags uchg $pleasewaitPhase > /dev/null 2>&1
 			# chflags schg $pleasewaitPhase > /dev/null 2>&1
		fi
		
		sleep 2
		echo "$actioncap in progress..." > "$pleasewaitPhase"
		echo "Now $actioning" "$heading" > "$pleasewaitProgress"
		
		# reset failsafe to change to the name of the installation
		# gives an indication of progress 

		echo "100" > "$pleasewaitInstallProgress"
	
	fi # long install with skipnotices off
	
	#############################
	# install during logout bar #
	#############################
# 	if [ -z $loggedInUser ] ; then
# 		status="$heading,
# 		Currently installing..."
# # 		"$jhPath" -icon "$icon" -windowType hud -windowPosition lr -startlaunchd -title "$title" -description "$status" > /dev/null 2>&1 &
# 		echo '#!/bin/bash' > /tmp/jamfhelperwindow.sh
# 		echo '"'"$jhPath"'"' -icon '"'"$icon"'"' -windowType hud -windowPosition lr -startlaunchd -title '"'"$title"'"' -description '"'"$heading is currently installing..."'"' >> /tmp/jamfhelperwindow.sh
# 		sh /tmp/jamfhelperwindow.sh &
# 	fi

##########################################################################################
##										INSTALL STAGE									##
##########################################################################################
	
	
	# Empty install folder
	/bin/rm "$installJSSfolder"* 2> /dev/null
	
	# Install notification Place holder
	# /usr/libexec/PlistBuddy -c "add name string ${heading}" "$UEXFolderPath"/install_jss/"$uexNameConsolidated".plist > /dev/null 2>&1
	# /usr/libexec/PlistBuddy -c "add checks string ${checks}" "$UEXFolderPath"/install_jss/"$uexNameConsolidated".plist > /dev/null 2>&1

	# added here to reduce Redundancy
	fn_addPlistValue "name" "string" "$heading4PleaseWait" "install_jss" "$uexNameConsolidated.plist"
	fn_addPlistValue "checks" "string" "$checks" "install_jss" "$uexNameConsolidated.plist"
	
	if [[ "$suspackage" = true ]] ; then
		#sus version 
		if [[ $appleUpdatesAvail = true ]] ; then
			logInUEX "Starting software updates"
			
			if [[ $diagblock = true ]] ; then
				fn_trigger "diagblock"
			fi
			
			##for #38 Check and unmount previous update disks 
			fn_EjectPreviouslyMountedUpdateDisks

			fn_execute_log4_JSS "softwareupdate -i --all -R"
		else
			logInUEX "Skipping uex no updates required"
		fi
	
		/bin/rm "$appleSUSlog" > /dev/null 2>&1
	
	fi

	# if [[ "$msupdate" = true ]] && [[ "$selfservicePackage" = true ]] ; then
	# 	#msupdate Version 
	# 	if [[ $msupdateUpdatesAvail = true ]] ; then
	# 		log4_JSS "Starting Microsoft Updates"
	# 		if [[ "$msUpdates2RunAfterUEX" ]] ; then
	# 			sudo -u "$currentConsoleUserName" "$msupdateBinary" -i -a "${msUpdates2RunAfterUEX[@]}"
	# 		fi
	# 	else
	# 		logInUEX "Skipping uex no updates required"
	# 	fi
	
	# 	/bin/rm "$msupdateLog" > /dev/null 2>&1
	
	# fi
	
	if [[ "$suspackage" != true ]] ; then
		# Go through list of packages and install them one by one
		for PKG in "${packages[@]}"; do
			
			# for #52
			# clear out the resultlogfilepath between package installs
			echo "" > "$resultlogfilepath"

			pathtopkg="$waitingRoomDIR"
			pkg2install="$pathtopkg""$PKG"
	
			logInUEX "Starting Install"
			
			if [[ "$PKG" == *".dmg" ]] && [[ "$checks" == *"feu"* ]] && [[ "$checks" == *"fut"* ]] ; then 
				"$jamfBinary" install -package "$PKG" -path "$pathtopkg" -feu -fut -target / | /usr/bin/tee -a "$resultlogfilepath"
				
			elif [[ "$PKG" == *".dmg" ]] && [[ "$checks" == *"fut"* ]] ; then
				"$jamfBinary" install -package "$PKG" -path "$pathtopkg" -fut -target / | /usr/bin/tee -a "$resultlogfilepath"
			else
				"$jamfBinary" install -package "$PKG" -path "$pathtopkg" -target / | /usr/bin/tee -a "$resultlogfilepath"
			fi

			#Debug Line
			logInUEX4DebugMode "exit code for installer is $?"
			
			##keeping this to search for values 
			# shellcheck disable=SC2002
			installResults=$( cat "$resultlogfilepath" | tr '[:upper:]' '[:lower:]' )
			if 	[[ "$installResults" == *"failed"* ]] || [[ "$installResults" == *"error"* ]] ; then
				failedInstall=true
			fi 
			
			echo "$(date)	$compname	:	RESULT: $(cat "$resultlogfilepath")" >> "$logfilepath"
	
			logInUEX "Install Completed"
			## No longer need to Delete the package from temp directory since the jamf binary does automatically
			# logInUEX "Deleting the package from temp directory"
			# logInUEX "Deleting $PKG"
			# /bin/rm "$pkg2install" 

		done
	fi
	
	if [[ "$checks" == *"trigger"* ]] ; then
		for trigger in "${triggers[@]}" ; do

			fn_trigger "$trigger"
			# echo "$jamfBinary" policy -forceNoRecon -trigger "$trigger"
			# "$jamfBinary" policy -forceNoRecon -trigger "$trigger" | /usr/bin/tee -a "$logfilepath"
		done
	fi
		
	##########################
	# Delay to test blocking #
	##########################
	#if theres a block requirement then delay or one minute so that it can be tested
	if [[ $debug = true ]] ; then
		if [[ "$checks" == *"block"* ]] ; then
			"$jhPath" -windowType hud -windowPosition ll -title "$title" -description "UEX Script Running in debug mode. Test your blocking now!" -button1 "OK" -timeout 30 > /dev/null 2>&1 &
			sleep 60
		fi
	fi
	#########################
	
	##################
	# Clear Deferral #
	##################
	# Delete defer plist so the agent doesn't start it again
	logInUEX "Deleting defer plist so the agent doesn not start it again"
	
	# go thourgh all the deferal plist and if any of them mention the same triggr then delete them
	## Need the plist as a file name in list format
	# shellcheck disable=SC2010
	plists=$( ls "$UEXFolderPath"/defer_jss/ | grep ".plist" )
	IFS=$'\n'
	for i in $plists ; do
		# deferPolicyTrigger=$( /usr/libexec/PlistBuddy -c "print policyTrigger" "$UEXFolderPath"/defer_jss/"$i" )
		deferPolicyTrigger=$(fn_getPlistValue "policyTrigger" "defer_jss" "$i")
		if [[ "$deferPolicyTrigger" == "$UEXpolicyTrigger" ]] ; then
			log4_JSS "Deleting $i"
			/bin/rm "$UEXFolderPath"/defer_jss/"$i" > /dev/null 2>&1
		fi
	done
	unset IFS
	
	
##########################################################################################
##								POST INSTALL ACTIONS									##
##########################################################################################






	#####################
	# Stop Progress Bar #
	#####################
	#stop the please wait daemon
	logInUEX "Stopping the PleaseWait LaunchDaemon."


	#only kill the pleaseWaitDaemon if it's running
	launchcltList=$( launchctl list )
	if [[ "$launchcltList" == *"github.cubandave.UEX-PleaseWait"* ]] ; then
		#statements
		launchctl unload -w $pleaseWaitDaemon > /dev/null 2>&1
	fi
	
	killall PleaseWait > /dev/null 2>&1
	
	# delete the daemon for cleanup #
	launchctl remove -w github.cubandave.UEX-PleaseWait > /dev/null 2>&1
	/bin/rm "$pleaseWaitDaemon" > /dev/null 2>&1
	
	# kill the app and clean up the files
	logInUEX "Quitting the PleaseWait application."
	killall PleaseWait > /dev/null 2>&1
	
	chflags nouchg $pleasewaitPhase > /dev/null 2>&1
	chflags noschg $pleasewaitPhase > /dev/null 2>&1
	
	/bin/rm $pleasewaitPhase > /dev/null 2>&1
	/bin/rm $pleasewaitProgress > /dev/null 2>&1
	/bin/rm $pleasewaitInstallProgress > /dev/null 2>&1
	
	# delete place holder
	/bin/rm "$UEXFolderPath"/install_jss/"$uexNameConsolidated".plist > /dev/null 2>&1


	###########################
	# Install Complete Notice #
	###########################
	
	#stop the currently installing if no one is logged in
	if [[ -z $loggedInUser ]] ; then
		killall jamfHelper
		
	fi
	
	if [[ "$selfservicePackage" = true ]] && [[ $skipNotices != "true" ]] || [[ $skipNotices != "true" ]]  ; then	
		status="$heading,
$action completed."
		if [[ "$loggedInUser" ]] ; then 
			"$CocoaDialog" bubble --title "$title" --text "$status" --icon-file "$icon"
		else
			"$jhPath" -icon "$icon" -windowType hud -windowPosition lr -startlaunchd -title "$title" -description "$status" -timeout 5 > /dev/null 2>&1 
		fi
		logInUEX "Notified user $heading, Completed"

	fi

	#####################################
	# 		MS UPDATES BACKGROUND	 	#
	#####################################
	# if [[ "$msupdate" = true ]] ; then
	# 	#msupdate Version 
	# 	if [[ $msupdateUpdatesAvail = true ]] ; then
	# 		if [[ "$msUpdates2RunSilent" ]] && [[ "$selfservicePackage" = true ]] ; then
	# 			log4_JSS "Installing Other MS Apps in background"
	# 			sudo -u "$currentConsoleUserName" "$msupdateBinary" -i -a "${msUpdates2RunSilent[@]}" &
	# 		fi
	# 	fi
	
	# 	/bin/rm "$msupdateLog" > /dev/null 2>&1
	
	# fi
	
	#####################
	# 		Block	 	#
	#####################
	if [[ "$checks" == *"block"* ]] ; then
		# delete the plist with properties to stop blocking
		logInUEX "Deleting the blocking plist"
		/bin/rm "$UEXFolderPath/block_jss/${uexNameConsolidated}.plist" > /dev/null 2>&1
		
		#kill all cocoaDialog windows 
		logInUEX "Killing cocoadialog window"
		kill "$( pgrep cocoaDialog )" > /dev/null 2>&1
	fi


	#####################
	# reopen apps      #
	#####################
	if [[ "$checks" != *"restart"* ]] && [[ "$checks" != *"logout"* ]] ; then
		for relaunchAppName in "${apps2Relaunch[@]}" ; do 
			app2Open=""
			appFound=""
			userAppFound=""
			# Find the apss in /Applications/ and ~/Applications/ and open as the user
			appFound=$( /usr/bin/find "/Applications" -maxdepth 3 -iname "$relaunchAppName" )
			userAppFound=$( /usr/bin/find "$loggedInUserHome/Applications" -maxdepth 3 -iname "$relaunchAppName" 2> /dev/null )
			
			if [[ "$appFound" ]] ; then
				app2Open="$appFound"
			elif [[ "$userAppFound" ]] ; then
				app2Open="$userAppFound"
			fi

			if [[ "$app2Open" ]] ;then
				# open the app as the user but in the background to it doesn't pull focus
				sudo -u "$loggedInUser" -H open -g "$app2Open"
			fi
		done
	fi

	#####################
	# 		Logout	 	#
	#####################
	if [[ "$checks" == *"logout"* ]] ; then
		# Start the agent to prompt logout
		logInUEX "Starting logout Daemon"
		triggerNgo uexlogoutagent &
	fi

	#####################
	# 		Restart	 	#
	#####################
	if [[ "$checks" == *"restart"* ]] ; then
		# Start the agent to prompt restart
		logInUEX "Starting restart Daemon"
		triggerNgo uexrestartagent &
	fi

fi

##########################################################################################
##								SELF SERVICE UNLOCK										##
##########################################################################################

if [[ "$selfservicePackage" = true ]] ; then
	 logInUEX "removing self service placeholder"
	/bin/rm "$SSplaceholderDIR""$uexNameConsolidated" > /dev/null 2>&1
fi

/bin/rm "$debugDIR""$uexNameConsolidated" > /dev/null 2>&1


##########################################################################################
##							Wrapping Error Ending for badVariable						##
##							DO NOT PUT ANY ACTIONS UNDER HERE							##
##########################################################################################
else
	failedInstall=true
	
	## No longer need to Delete the package from temp directory since the jamf binary does automatically
	# for PKG in "${packages[@]}"; do
			# logInUEX "Deleting the package from temp directory"
			# logInUEX "Deleting $PKG"
			# /bin/rm "$pkg2install"
	# done
		

fi # Installations ''

##########################################################################################
# 										LOG CLEANUP										 #
##########################################################################################
rm "$resultlogfilepath" > /dev/null 2>&1 

/bin/rm /Library/LaunchAgents/github.cubandave.UEX-jamfhelper.plist > /dev/null 2>&1 

if [[ "$InventoryUpdateRequired" = true ]] ;then 
	log4_JSS "Inventory Update Required"
	triggerNgo uex_inventory_update_agent
fi


logInUEX "******* script complete *******"
echo "" >> "$logfilepath"
echo "" >> "$logfilepath"

if [[ "$failedInstall" = true ]] ; then 
	exit 1
else
	exit 0
fi

##########################################################################################
##									Version History										##
##########################################################################################
# 
# 
# Jan 18, 2016 	v1.0	--cubandave--	Stage 1 Delivered
# Apr 4, 2016 	v1.1 	--cubandave--	Updated PKG system for multiple PKG file Installation 
# May 9, 2016 	v1.2 	--cubandave--	Adding silence to notices in case no one is logged in. 
# May 22, 2016	v1.3	--cubandave--	deferral-service-1.3 added
# May 22, 2016	v1.3	--cubandave--	Added Power check for laptop with intelligence on connection
# May 22, 2016	v1.3	--cubandave-- 	Added maxdefer option for multiple postpones
# May 22, 2016	v1.3	--cubandave--	Added descriptors for UEX Parameters
# May 22, 2016	v1.3	--cubandave--	Standardized title on windows
# May 22, 2016	v1.3	--cubandave--	added install at logout feature with deferral-service-1.3
# Jul 29, 2016	v2.0	--cubandave--	**** ADDED LOGGING*** -- see logging templates for more info
# Jul 29, 2016	v2.0	--cubandave--	added block application for smarter blocking in case applications are not installed.
# Jul 29, 2016	v2.0	--cubandave--	^^^^^^^ see UEX paramaters for more details on block detection 
# Jul 29, 2016	v2.0	--cubandave--	change to hud view until JAMF can fix the utility window on postpones 
# Aug 24, 2016	v2.0	--cubandave--	selfservicePackage skip option added use place holder script with PKG name to enable.
# Sep 5, 2016	v2.0	--cubandave--	Debug mode now has a place holder script with PKG name to enable.
# Sep 5, 2016	v2.0	--cubandave--	all daemons updated to v2.0 to add logging
# 
# 
# 
# Insert TONS of Updates for update 3.0 ;-)
# Jan 23, 2017 	v3.0	--cubandave--	Stage 3 Delivered to run from Jamf Pro directly
# Jul 12, 2017	v3.1	--cubandave--	added new icons and support for custom notification (check = custom)
# Sep 22, 2017	v3.2	--cubandave--	Added Support for Catching in the script
# Sep 30, 2017	v3.3	--cubandave--	added suport for choosing if inventory updates should apply
# Nov 30, 2017	v3.4	--cubandave--	updated with world of apps icons
# Feb 08, 2018	v3.5	--cubandave--	added macosupgrade and elements for lock and saveallwork, & loginwindow
# Feb 08, 2018	v3.5	--cubandave--	fixed elements where pollies run at loginwidow if notify is specified
# Feb 08, 2018	v3.5	--cubandave--	added countdown to are you sure
# Mar 26, 2018	v3.5	--cubandave--	added deferal clears all pospones by the trigger name instead to prevent repeated runs
# Apr 24, 2018 	v3.7	--cubandave--	Funtctions added for plist processing
# Jun 3, 2018 	v3.7.2	--cubandave--	Names are generic and self service app name is dynamic
# Jun 3, 2018 	v3.7.3	--cubandave--	Dynamic detection of Self Service locaiton for messaging
# Aug 26, 2018	v3.8	--cubandave--	Added a compliance and force install mechanism for force instllatation, 
# Aug 26, 2018	v3.8	--cubandave--	Security, macOS and Firmware added as complance policies
# Aug 26, 2018	v3.8	--cubandave--	Quitting Jamf helper now acts as if you've ignored it triggering inactivity delay.
# Aug 26, 2018	v3.8	--cubandave--	moved some logging to debug mode only and increase logging on UEX dialogs
# Sep 11, 2018	v3.8	--cubandave--	making reopen apps function built in
# Oct 24, 2018 	v4.0	--cubandave--	All Change logs are available now in the release notes on GITHUB
# 
# 
