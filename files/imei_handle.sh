#!/bin/ash

show_usage_exit()
{
	echo "Usage:"
	echo "       $0 x750_fixtac"
	echo "       $0 x750_setimei <new_imei>"
	echo "       $0 check <old_IMEI>"
	echo "       $0 fixtac <TAC> <old_IMEI>"
	exit 1	
}

cal_sum_bit()
{
	local val=$1
	local sum esum csum
	esum=0
	for i in 0 2 4 6 8 10 12;do
		let esum=esum+${val:$i:1}
	done
	csum=0
	for i in 1 3 5 7 9 11 13;do
		local v
		let v=${val:$i:1}*2
		for j in $(seq 0 ${#v});do
			[ $j = ${#v} ] && break
			let csum=csum+${v:$j:1}
		done
	done
	let sum=esum+csum
	let sum=sum%10
	[ $sum = 0 ] || let sum=10-sum
	echo $sum
}

check_imei_valid()
{
	local val=$1
	[ ${#val} = 15  ] || {
		echo "$val is invalid IMEI,the length should be 15 bit"
		return 1
	}
	[ "$val" -gt 0 ] || {
		echo "$val is invalid IMEI,the type of imei should be number"
		return 1
	}
	local tsum=$(cal_sum_bit $val)
	if [ $tsum = ${val:14:1} ];then
		echo "$val is a valid IMEI"
		return 0
	else
		echo "$val is invalid IMEI,the sum bit should be $tsum"
		return 1
	fi
		
}

gen_new_imei()
{
	local TAC=$1
	local OLD=$2

	[ ${#TAC} = 8  ] || {
		echo "The TAC length should be 8 bit"
		return 1
	}
	[ "$TAC" -gt 0 ] || {
		echo "$TAC is invalid TAC,the type of TAC should be number"
		return 1
	}

	[ ${#OLD} = 15  ] || {
		echo "The OLD IMEI length should be 15 bit"
		return 1
	}
	[ "$OLD" -gt 0 ] || {
		echo "$OLD is invalid IMEI,the type of imei should be number"
		return 1
	}
	local TMPVAL=$TAC${OLD:8:6}0
	local sumbit=$(cal_sum_bit $TMPVAL)
	local NEW=${TMPVAL:0:14}$sumbit
	echo $NEW
	return 0
}

# A special IMEI needs to be replaced with another IMEI address. 
# This function checks the special IMEI and returns the replaced value.
get_special_imei()
{
	local check=${1:0:14}
	[ -e "/usr/share/special_imei.txt" ] || return 0
	local special="$(grep $check /usr/share/special_imei.txt)"
	[ -z "$special" ] && return 0
	local new="$(echo $special|cut -d ' ' -f 2)"
	[ -n "$new" ] && echo $new
	return 0
}

x750_fix_tac()
{
	local bus="1-1.2"
	local node="1-1.2:1.2"
	local atcmd=$([ -x /usr/bin/sendat ] && echo "/usr/bin/sendat" || echo "/usr/bin/gl_modem")
	local devpath="$(find  /sys/devices/ -name "$node")"
	local dev="$(find "$devpath" -name  "ttyUSB*"|head -n 1)"
	dev=/dev/"$(basename "$dev")"

	local old="$($atcmd -B $bus AT $dev AT+EGMR=0,7|grep +EGMR:|tr -cd "0-9")"
	check_imei_valid $old || return 1
	#whether need to be fixing?
	[ ${old:0:8} = 35851102 ] || return 0

	#first,check old imei is special imei
	local new="$(get_special_imei $old)"
	#if not special, generic new imei use tac 35996594
	[ -z "$new" ]  && new=$(gen_new_imei 35996594 $old)
	check_imei_valid $new || return 1
	
	local ret="$($atcmd -B $bus AT $dev AT+EGMR=1,7,\"$new\"|grep OK)"
	[ -z "$ret" ] && return 1
	$atcmd -B $bus AT $dev "AT+QPRTPARA=1" 2>&1 >/dev/null
	local now="$($atcmd -B $bus AT $dev AT+EGMR=0,7|grep +EGMR:|tr -cd "0-9")"
	if [ "$now" = "$new" ]; then
		return 0
	else
		return 1
	fi
}

x750_set_imei()
{
	local new="$1"
	local bus="1-1.2"
	local node="1-1.2:1.2"
	local atcmd=$([ -x /usr/bin/sendat ] && echo "/usr/bin/sendat" || echo "/usr/bin/gl_modem")
	local devpath="$(find  /sys/devices/ -name "$node")"
	local dev="$(find "$devpath" -name  "ttyUSB*"|head -n 1)"
	dev=/dev/"$(basename "$dev")"
	check_imei_valid $new || return 1

	local old="$($atcmd -B $bus AT $dev AT+EGMR=0,7|grep +EGMR:|tr -cd "0-9")"
	check_imei_valid $old || return 1
	
	local ret="$($atcmd -B $bus AT $dev AT+EGMR=1,7,\"$new\"|grep OK)"
	[ -z "$ret" ] && return 1
	$atcmd -B $bus AT $dev "AT+QPRTPARA=1" 2>&1 >/dev/null
	local now="$($atcmd -B $bus AT $dev AT+EGMR=0,7|grep +EGMR:|tr -cd "0-9")"
	if [ "$now" = "$new" ]; then
		return 0
	else
		return 1
	fi
}


[ $# -lt 1 ] && show_usage_exit $@

case $1 in
	"check")
		[ $# -lt 2 ] && show_usage_exit $@
		shift
		check_imei_valid $@
		exit $?
		;;
	"fixtac")
		[ $# -lt 3 ] && show_usage_exit $@
		shift
		new=$(gen_new_imei $@)
		check_imei_valid $new
		exit $?
		;;
	"x750_fixtac")
		x750_fix_tac
		exit $?
		;;
	"x750_setimei")
		[ $# -lt 2 ] && show_usage_exit $@
		shift
		x750_set_imei $@
		exit $?
		;;
	*)
		show_usage_exit $@
esac


