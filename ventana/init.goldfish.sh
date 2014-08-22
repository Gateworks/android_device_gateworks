#!/system/bin/sh

# get board from cmdline
for x in `cat /proc/cmdline`; do
  [[ $x = androidboot.board=* ]] || continue
  board="${x#androidboot.board=}"
done

# as fallback get from eeprom manually
[ -z "$board" ] && {
	board=`dd if=/sys/devices/platform/imx-i2c.0/i2c-0/0-0050/eeprom \
		bs=1 count=16 skip=304 2>/dev/null | busybox hexdump -C | \
		busybox head -1 | busybox cut -c62-65`
}

echo "BOARD:$board"

orientation=
case "$board" in
	GW54)
		orientation=0
		gps_device=/dev/ttymxc4
		# GPIO mappings
		setprop gpio.dio0 9
		setprop gpio.dio1 19
		setprop gpio.dio2 41
		setprop gpio.dio3 42
		;;
	GW53)
		orientation=3
		gps_device=/dev/ttymxc4
		# GPIO mappings
		setprop gpio.dio0 16
		setprop gpio.dio1 19
		setprop gpio.dio2 17
		setprop gpio.dio3 20
		;;
	GW52)
		orientation=3
		gps_device=/dev/ttymxc4
		# GPIO mappings
		setprop gpio.dio0 16
		setprop gpio.dio1 19
		setprop gpio.dio2 17
		setprop gpio.dio3 20
		;;
	GW51)
		gps_device=/dev/ttymxc0
		# GPIO mappings
		setprop gpio.dio0 16
		setprop gpio.dio1 19
		setprop gpio.dio2 17
		setprop gpio.dio3 20
		;;
	*)
		echo "unknown board: $board"
		;;
esac

# Accelerometer/Magnetometer physical orientation
[ "$orientation" ] && {
	echo $orientation > /sys/devices/virtual/input/input0/position
}

# GPS configuration
gps_present=1
[ $gps_present ] && {
	ln -s $gps_device /dev/gpsdevice
	# set gps baudrate to 115200
	busybox stty -F /dev/gpsdevice 4800
	echo "\$PSRF100,1,115200,8,1,0*05" > /dev/gpsdevice
	busybox stty -F /dev/gpsdevice 115200
	# configure message reporting rate (third field is period in secs):
	echo "\$PSRF103,00,00,01,01*25" > /dev/gpsdevice # GGA
	echo "\$PSRF103,01,00,01,01*24" > /dev/gpsdevice # GLL
	echo "\$PSRF103,02,00,01,01*27" > /dev/gpsdevice # GSA
	echo "\$PSRF103,03,00,01,01*26" > /dev/gpsdevice # GSV
	echo "\$PSRF103,04,00,01,01*21" > /dev/gpsdevice # RMC
	echo "\$PSRF103,05,00,01,01*20" > /dev/gpsdevice # VTG
}

# export DIO's and configure them all as inputs
# but allow user 'system' to modify value and direction
i=0
while [ 1 ]; do
	gpio=$(getprop gpio.dio${i})
	[ "$gpio" ] || break


	# export
	echo ${gpio} > /sys/class/gpio/export
	# configure as output-low
	echo out > /sys/class/gpio/gpio${gpio}/direction
	echo 0 > /sys/class/gpio/gpio${gpio}/value
	# allow all users to modify value
	chown system.system /sys/class/gpio/gpio${gpio}/value
	chmod 0666 /sys/class/gpio/gpio${gpio}/value
	# allow all users to modify direction
	chown system.system /sys/class/gpio/gpio${gpio}/direction
	chmod 0666 /sys/class/gpio/gpio${gpio}/direction
	i=$((i+1))
done
