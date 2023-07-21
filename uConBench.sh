#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPTPATH=`dirname $SCRIPT`
BACKLIGHT="/sys/class/backlight/backlight@0/brightness"

OLD_BACKLIGHT=`cat /sys/class/backlight/backlight@0/brightness`
echo 0 > $BACKLIGHT

$SCRIPTPATH/uConStat.lua &
$@ &> /dev/null
pkill uConStat.lua

echo $OLD_BACKLIGHT > $BACKLIGHT
