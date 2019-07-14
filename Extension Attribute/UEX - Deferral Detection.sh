#!/bin/bash

fn_read_uex_Preference () {
	local domain="$1"
	defaults read /Library/Preferences/github.cubandave.uex.plist "$domain"
}

UEXFolderPath="$(fn_read_uex_Preference "UEXFolderPath")"
# in case the plist hasn't been create on this version then set it to the previous standard
if [[ -z "$UEXFolderPath" ]] ; then
	UEXFolderPath="/Library/Application Support/JAMF/UEX"
fi

moredefer=$( ls "$UEXFolderPath"/defer_jss/*.plist )
if [[ -z $moredefer ]] ; then 
	result="none"
else
	result="active"
fi

echo "<result>$result</result>"