#!/bin/bash
# set -x

##########################################################################################
##								Jamf Interaction Configuration 							##
##########################################################################################


printf "Enter your jss_url [Default: https://cubandave.local:8443]:\n"
read -r jss_url
jss_url="${jss_url:-https://cubandave.local:8443}"

printf "Enter an admin user name for your Jamf Server [Default: jssadmin]:\n"
read -r jss_user
jss_user="${jss_user:-jssadmin}"

printf "Enter the password for the user [Default: jamf1234]:\n"
read -s -r jss_pass
jss_pass="${jss_pass:-jamf1234}"


# jss_url="https://cubandave.local:8443"
# jss_user="jssadmin"
# jss_pass="jamf1234"

# Set the category you'd like to use for all the policies

printf "Enter the name of the category you want to use to testing [Default: User Experience Testers]:\n"
read -r UEXTesterCategoryName
UEXTesterCategoryName="${UEXTesterCategoryName:-User Experience Testers}"




##########################################################################################
# 								Do not change anything below!							 #
##########################################################################################

triggerscripts=(
	"00-UEX-Deploy-via-Trigger"
	"00-UEX-Install-via-Self-Service"
	"00-UEX-Update-via-Self-Service"
)

UEXInteractionScript="00-UEX-Jamf-Interaction-no-grep"

##########################################################################################
# 										Functions										 #
##########################################################################################
fn_makeBase64Auth () {
	base64Auth=$( /bin/echo -n "$jss_user:$jss_pass" | /usr/bin/base64 )
}

FNputXML () 
	{
		# echo /usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/$2" -H "Authorization: Basic $base64Auth" -H \"Content-Type: text/xml\" -X PUT -d "$3"
		/usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/$2" -H "Authorization: Basic $base64Auth" -H "Content-Type: text/xml" -X PUT -d "$3" > /dev/null
    }

FNpostXML () 
	{
		# echo /usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/0" -H "Authorization: Basic $base64Auth" -H \"Content-Type: text/xml\" -X POST -d "$2"
		/usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/0" -H "Authorization: Basic $base64Auth" -H "Content-Type: text/xml" -X POST -d "$2" > /dev/null
    }

FNput_postXML () 
	{

	FNgetID "$1" "$2"
	pid=$retreivedID

	if [ "$pid" ] ; then
		echo "updating $1: ($pid) \"$2\"" 
		FNputXML "$1" "$pid" "$3"
		# echo ""
	else
		echo "creating $1: \"$2\""
		FNpostXML "$1" "$3"
		# echo ""
	fi

	FNtestXML "$1" "$2"
	}

FNput_postXMLFile () 
	{

	FNgetID "$1" "$2"
	pid=$retreivedID

	if [ "$pid" ] ; then
		echo "updating $1: ($pid) \"$2\"" 
		FNputXMLFile "$1" "$pid" "$3"
		# echo ""
	else
		echo "creating $1: \"$2\""
		FNpostXMLFile "$1" "$3"
		# echo ""
	fi

	FNtestXML "$1" "$2"
	}

FNputXMLFile () 
	{	# echo /usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/$2" -H "Authorization: Basic $base64Auth" -H \"Content-Type: text/xml\" -X PUT -d "$3"
		/usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/$2" -H "Authorization: Basic $base64Auth" -H "Content-Type: text/xml" -X PUT -T "$3"
	}


FNpostXMLFile () 
	{
		# echo /usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/0" -H "Authorization: Basic $base64Auth" -H \"Content-Type: text/xml\" -X POST -d "$2"
		/usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/0" -H "Authorization: Basic $base64Auth" -H "Content-Type: text/xml" -X POST -T "$2"
	}

FNtestXML () 
	{

	FNgetID "$1" "$2"
	pid=$retreivedID

	if [ -z "$pid" ] ; then
		# echo ""$1" \"$2\" exists ($pid)" 
		# echo ""
	# else
		echo "ERROR $1 \"$2\" does not exist" 
		exit 1
	fi
	}

FNgetID () 
	{
		retreivedID=""
		retreivedXML=""
		name="$2"

		retreivedID=$( /usr/bin/curl -s -k "${jss_url}/JSSResource/$1" -H "Authorization: Basic $base64Auth" -H "Accept: application/xml" | xmllint --format - | grep -B 1 "$name" | /usr/bin/awk -F'<id>|</id>' '{print $2}' | sed '/^\s*$/d' )

    }

FNgetXML () 
	{
		local resourceName="$1"
		local IDtoRead="$2"

		retreivedXML=$( /usr/bin/curl -s -k "${jss_url}/JSSResource/$resourceName/id/$IDtoRead" -H "Authorization: Basic $base64Auth" -H "Accept: application/xml" )

    }

FNcreateCategory () {
	CategoryName="$1"
	newCategoryNameXML="<category><name>$CategoryName</name><priority>9</priority></category>"

	FNput_postXML categories "$CategoryName" "$newCategoryNameXML"
	FNgetID categories "$CategoryName"
}

fn_createAgentPolicy () {
	local scriptID=""
	local policyScript="$1"
	local policyTrigger="$2"
	local agentPolicyName
	agentPolicyName="${policyScript//.sh}"
	local agentPolicyName+=" - Trigger"
	# echo "$agentPolicyName"

	FNgetID scripts "$policyScript"
	local scriptID="$retreivedID"

	local agentPolicyXML="<policy>
  <general>
    <name>$agentPolicyName</name>
    <enabled>true</enabled>
    <trigger>EVENT</trigger>
    <trigger_other>$policyTrigger</trigger_other>
    <frequency>Ongoing</frequency>
    <category>
      <id>$UEXTesterCategoryID</id>
    </category>
  </general>
  <scope>
    <all_computers>true</all_computers>
  </scope>
  <scripts>
    <size>1</size>
    <script>
      <id>$scriptID</id>
      <priority>After</priority>
    </script>
  </scripts>
</policy>"

FNput_postXML "policies" "$agentPolicyName" "$agentPolicyXML"

}

fn_createAPIPolicy () {
	local scriptID=""
	local policyScript="$1"
	local policyTrigger="$2"
	local APIPolicyName 
	APIPolicyName="${policyScript//.sh}"
	local APIPolicyName+=" - Disk Space - Trigger"
	local parameter4="$3"
	local parameter5="$4"
	# echo "$APIPolicyName"

	FNgetID scripts "$policyScript"
	local scriptID="$retreivedID"

	FNgetID "policies" "$APIPolicyName"
	if [ "$retreivedID" ] ; then
		FNgetXML "policies" "$retreivedID"

		parameter6=$( echo "$retreivedXML" | xmllint --xpath "/policy/scripts/script/parameter6/text()" - )
		parameter7=$( echo "$retreivedXML" | xmllint --xpath "/policy/scripts/script/parameter7/text()" - )
	fi

	local APIPolicyXML="<policy>
  <general>
    <name>$APIPolicyName</name>
    <enabled>true</enabled>
    <trigger>EVENT</trigger>
    <trigger_other>$policyTrigger</trigger_other>
    <frequency>Ongoing</frequency>
    <category>
      <id>$UEXTesterCategoryID</id>
    </category>
  </general>
  <scope>
    <all_computers>true</all_computers>
  </scope>
  <scripts>
    <size>1</size>
    <script>
      <id>$scriptID</id>
      <priority>After</priority>
      <parameter4>$parameter4</parameter4>
      <parameter5>$parameter5</parameter5>
      <parameter6>$parameter6</parameter6>
      <parameter7>$parameter7</parameter7>
    </script>
  </scripts>
</policy>"

FNput_postXML "policies" "$APIPolicyName" "$APIPolicyXML"

}

fn_checkForSMTPServer () {
	/usr/bin/curl -s -k "${jss_url}/JSSResource/smtpserver" -H "Authorization: Basic $base64Auth" -H "Accept: application/xml" | xmllint --format - | grep -c "<enabled>true</enabled>"
}

fn_createTriggerPolicy () {
	local triggerPolicyName="$1"
	local policyTrigger2Run="$2"
	FNgetID "scripts" "00-UEX-Deploy-via-Trigger"
	local triggerScripID="$retreivedID"
	local triggerPolicyScopeXML="$3"

	local triggerPolicyXML="<policy>
  <general>
    <name>$triggerPolicyName</name>
    <enabled>true</enabled>
    <trigger_checkin>true</trigger_checkin>
    <trigger_logout>true</trigger_logout>
    <frequency>Ongoing</frequency>
    <category>
      <id>$UEXTesterCategoryID</id>
    </category>
  </general>
  <scope>
	$triggerPolicyScopeXML
  </scope>
  <scripts>
    <size>1</size>
    <script>
      <id>$triggerScripID</id>
      <priority>After</priority>
      <parameter4>$policyTrigger2Run</parameter4>
    </script>
  </scripts>
</policy>"

FNput_postXML "policies" "$triggerPolicyName" "$triggerPolicyXML"

}


fn_createTriggerPolicy4Pkg () {
	local packagePolicyName="$1"
	local pkg2Install="$2"
	local customEventName="$3"
	FNgetID "packages" "$pkg2Install"
	local policypackageID="$retreivedID"
	local packagePolicyScopeXML="$4"

	local packagePolicyXML="<policy>
  <general>
    <name>$packagePolicyName</name>
    <enabled>true</enabled>
    <trigger>EVENT</trigger>
    <trigger_other>$customEventName</trigger_other>
    <frequency>Ongoing</frequency>
    <category>
      <id>$UEXTesterCategoryID</id>
    </category>
  </general>
  <scope>
	$packagePolicyScopeXML
  </scope>
  <package_configuration>
    <packages>
      <size>1</size>
      <package>
        <id>$policypackageID</id>
        <action>Install</action>
      </package>
    </packages>
  </package_configuration>
</policy>"

FNput_postXML "policies" "$packagePolicyName" "$packagePolicyXML"
}

fn_find_last_PKG_fromString () {
	local packageString="$1"
	local string="$2"
	/usr/bin/curl -s -k "${jss_url}/JSSResource/packages" -H "Authorization: Basic $base64Auth" -H "Accept: application/xml" | xmllint --format - | grep -B 1 "$packageString" | /usr/bin/awk -F "<$string>|</$string>" '{print $2}' | sed '/^\s*$/d' | tail -n 1
}


fn_Create_test_UEX_package_cache_policy () {
	local name="$1"
	local packagePolicyName="$2"
	local triggerName="$3"
	local pkgid
	pkgid=$(fn_find_last_PKG_fromString "$packagePolicyName" "id")

	local uexTriggerPolicyXML
	uexTriggerPolicyXML="<policy>
  <general>
    <name>$name</name>
    <enabled>true</enabled>
    <trigger>EVENT</trigger>
    <trigger_other>$triggerName</trigger_other>
    <frequency>Ongoing</frequency>
    <category>
      <id>$UEXTesterCategoryID</id>
    </category>
    <site>
      <id>-1</id>
    </site>
  </general>
  <scope>
    <all_computers>true</all_computers>
  </scope>
  <package_configuration>
    <packages>
      <size>1</size>
      <package>
        <id>$pkgid</id>
        <action>Cache</action>
      </package>
    </packages>
  </package_configuration>
	</policy>"

	FNput_postXML "policies" "$name" "$uexTriggerPolicyXML"

}

fn_Create_test_UEX_policy (){
	local Vendor="$1"
	local appName="$2"
	local version="$3"
	local spaceRequired="$4" 
	local checks="$5"
	local apps="$6"
	local InstallDuration="$7"
	local maxdefer="$8"
	local packageString="$9"

	UEXtriggerPolicyName="$appName - UEX Trigger"
	UEXtriggerPolicyCacheName="$appName - UEX Package Cache"
	triggerName="${appName// /_}"

	cachingtriggerName="$triggerName"
	cachingtriggerName+="_cache"
	param4="$Vendor;$appName;$version"
	if [[ "$spaceRequired" ]] ;then
		param4+=";$spaceRequired"
	fi

	# set default of 3 if max defer is blank
	maxdefer="${maxdefer:-3}"

	local pkgName
	pkgName=$(fn_find_last_PKG_fromString "$packageString" "name")

	fn_Create_test_UEX_package_cache_policy "$UEXtriggerPolicyCacheName" "$pkgName" "$cachingtriggerName"

	local uexTriggerPolicyXML
	uexTriggerPolicyXML="<policy>
  <general>
    <name>$UEXtriggerPolicyName</name>
    <enabled>true</enabled>
    <trigger>EVENT</trigger>
    <trigger_other>$triggerName</trigger_other>
    <frequency>Ongoing</frequency>
    <category>
      <id>$UEXTesterCategoryID</id>
    </category>
    <site>
      <id>-1</id>
    </site>
  </general>
  <scope>
    <all_computers>true</all_computers>
  </scope>
  <scripts>
    <size>1</size>
    <script>
      <id>$UEXInteractionScriptID</id>
      <priority>After</priority>
      <parameter4>$param4</parameter4>
      <parameter5>$checks</parameter5>
      <parameter6>$apps</parameter6>
      <parameter7>$InstallDuration</parameter7>
      <parameter8>$maxdefer</parameter8>
      <parameter9>$pkgName</parameter9>
      <parameter10>$triggerName</parameter10>
      <parameter11/>
    </script>
  </scripts>
	</policy>"

	FNput_postXML "policies" "$UEXtriggerPolicyName" "$uexTriggerPolicyXML"

	for triggerscript in "${triggerscripts[@]}" ; do
		fn_createTriggerTesters "$triggerscript" "$appName" "$triggerName"
	done
}

fn_createTriggerTesters () {
	local triggerscript="$1"
	local appName="$2"
	local policyName="$appName - $triggerscript - Test"
	local trigger="$3"

	FNgetID "scripts" "$triggerscript"
	local scriptID
	scriptID="$retreivedID"
	

	local triggerPolicyXML
	triggerPolicyXML="<policy>
  <general>
    <id>76</id>
    <name>$policyName</name>
    <enabled>true</enabled>
    <frequency>Ongoing</frequency>
    <category>
      <id>$UEXTesterCategoryID</id>
    </category>
    <site>
      <id>-1</id>
    </site>
  </general>
  <scope>
    <all_computers>true</all_computers>
  </scope>
  <self_service>
    <use_for_self_service>true</use_for_self_service>
  </self_service>
  <scripts>
    <size>1</size>
    <script>
      <id>$scriptID</id>
      <priority>After</priority>
      <parameter4>$trigger</parameter4>
      <parameter5/>
      <parameter6/>
      <parameter7/>
      <parameter8/>
      <parameter9/>
      <parameter10/>
      <parameter11/>
    </script>
  </scripts>
	</policy>"

	FNput_postXML "policies" "$policyName" "$triggerPolicyXML"

}


##########################################################################################
# 								Script Starts Here										 #
##########################################################################################

# Making Curl more secure
fn_makeBase64Auth

# create category
	FNcreateCategory "$UEXTesterCategoryName"
	UEXTesterCategoryID="$retreivedID"


	FNgetID "scripts" "$UEXInteractionScript"
	UEXInteractionScriptID="$retreivedID"

	fn_Create_test_UEX_policy "Google" "Google Chrome" "1.0" "" "quit ssavail" "Google Chrome.app" "1" "" "GoogleChrome"
	fn_Create_test_UEX_policy "Citrix" "Citrix Workspace" "1.0" "" "quit logout ssavail" "Citrix Receiver.app;Citrix Workspace.app" "5" "" "Citrix_Workspace"
	fn_Create_test_UEX_policy "Adobe" "Adobe Flash Player" "1.0" "" "quit ssavail" "Safari.app" "5" "" "AdobeFlashPlayer"
	fn_Create_test_UEX_policy "Wacom" "Wacom Intuos Driver" "1.0" "" "restart ssavail" "" "15" "" "Wacom Intuos Driver"
	fn_Create_test_UEX_policy "VMWare" "VMware Tools" "1.0" "" "restart compliance ssavail" "" "1" "1" "VMwareTools"
	fn_Create_test_UEX_policy "MS" "Skype For Business" "1.0" "" "quit ssavail" "Skype for Business.app" "1" "" "Skype For Business"
	fn_Create_test_UEX_policy "MS" "Officie 365" "1.0" "" "block ssavail" "Microsoft Excel.app;Microsoft OneNote.app;Microsoft Outlook.app;Microsoft PowerPoint.app;Microsoft Word.app;OneDrive.app" "30" "" "Microsoft_Office_Suite"
	fn_Create_test_UEX_policy "MS" "Microsoft Teams" "1.0" "" "block ssavail" "Microsoft Teams.app" "10" "" "Microsoft_Teams"


# update scripts paramters
	

echo "The world is now your burrito!"


##########################################################################################
exit 0
