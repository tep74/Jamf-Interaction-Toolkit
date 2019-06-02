#!/bin/bash

jhPath="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"


checksOriginal="question button1default;button2default:Bitte"
checks=`echo "$checksOriginal" | tr '[:upper:]' '[:lower:]'`


triggers=${10}
triggers="runme;button1:scsw"



checksarray=($checksOriginal)

customMessage=${11}
customMessage="Would you like this super cool software?"

questionMessageDesc="$customMessage"
if [[ "$checks" == *"button1default"* ]] && [[ "$checks" == *"button2default"* ]]; then
	echo button 1 and button 2 are the same. please make a choices
fi

if [[ "$checks" == *"button"*  ]]; then

	for checkItem in ${checksarray[@]}; do
		#statements
		checkItemLC=`echo $checkItem | tr '[:upper:]' '[:lower:]'`
		if [[ $checkItemLC == *"button1"* ]]; then
			#statements
			button1=`echo $checkItem | awk -F ':' '{ print $2 }'`
		elif [[ $checkItemLC == *"button2"* ]]; then
			#statements
			button2=`echo $checkItem | awk -F ':' '{ print $2 }'`
		fi
		
	done

fi

if [[ "$checks" == *"question"* ]]; then
	if [[ -z "$button1" ]]; then
		button1=Yes
	fi

	if [[ -z "$button2" ]]; then
		button2=No
	fi
fi


if [[ "$checks" == *"question"* ]]; then
		button1ReturnValue=0
		button2ReturnValue=2

	if [[ "$checks" == *"button1default"* ]]; then
		defaultButton=1
	elif [[ "$checks" == *"button2default"* ]]; then
		defaultButton=2
	else
		noDefaultButton=true
	fi
fi

if [[ "$checks" == *"question"* ]]; then

	if [[ "$checks" == *"default"* ]]; then
		PostponeClickResult=`"$jhPath" -windowType hud -lockHUD -button1 "$button1" -button2 "$button2" -defaultButton "$defaultButton" -description "$questionMessageDesc"`
	else
		PostponeClickResult=`"$jhPath" -windowType hud -lockHUD -button1 "$button1" -button2 "$button2" -description "$questionMessageDesc"`
	fi
fi





IFS=";"

set -- "$triggers" 
declare -a triggers=($*)

unset triggers[0]

unset IFS


if [[ "$checks" == *"question"* ]]; then
	for triggername in ${triggers[@]}; do
		triggernameToCheckLC=`echo $triggername | tr '[:upper:]' '[:lower:]'`
		if [[ "$triggernameToCheckLC" == *"button1"* ]]; then
			#statements
			button1Trigger=`echo $triggernameToCheckLC | awk -F ':' '{ print $2 }'`
		elif [[ "$triggernameToCheckLC" == *"button2"* ]]; then
			#statements
			button2Trigger=`echo $triggernameToCheckLC | awk -F ':' '{ print $2 }'`
		fi
	done


	if [[ -z "$button2Trigger" ]]; then
		#statements
		doNothingonButton2=true
	fi
fi




if [[ $PostponeClickResult = $button1ReturnValue ]]; then
	#statements
	echo User clicked on "$button1" so i am moving forward with action
	if [[ "$button1Trigger" ]] ; then
		echo now i must run policy "$button1Trigger"
	else
		echo this is a package installation only
	fi
elif [[ $PostponeClickResult = $button2ReturnValue ]] && [[ $button2Trigger ]]; then
	#statements
	echo User clicked on "$button2" now i must run policy "$button2Trigger"
elif [[ $PostponeClickResult = $button2ReturnValue ]] ; then
	#statements
	echo User clicked on "$button2" so i am doing nothing
elif [[ $PostponeClickResult = 239 ]]; then
	#statements
	echo now i must run nothing
fi