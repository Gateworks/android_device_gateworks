#!/system/bin/sh

#
# board-specific initialization requires some scripting intelligence not
# supported by Androids init system syntax. Therefore we run this script
# as a one-shot from Androids init-system at late_start.
#
# board-specific details handled here:
#  - DIO<n> gpio abstraction via gpio.dio<n> properties
#  - DIO<n> gpio sysfs permissions
#  - GPS UART device specification
#  - initial GPS configuration
#  - accelerometer orientation adjustment
#
CAN_ARGS="bitrate 250000 listen-only off"

# $1 number
# $2 name
# $3 output level (if not input)
gpio() {
	local num=$1
	local name=$2
	local output=$3

	echo "$pre: gpio$num: $name" > /dev/console
	[ -d /sys/class/gpio/gpio$num ] || {
		echo $num > /sys/class/gpio/export
	}
	[ "$output" ] && {
		echo out > /sys/class/gpio/gpio$num/direction
		echo $output > /sys/class/gpio/gpio$num/value
	}

	# allow all users to modify value
	chown system.system /sys/class/gpio/gpio${num}/value
	chmod 0666 /sys/class/gpio/gpio${num}/value
	# allow all users to modify direction
	chown system.system /sys/class/gpio/gpio${num}/direction
	chmod 0666 /sys/class/gpio/gpio${num}/direction

	# set property to map the name to device
	setprop gpio.$name $num
}

# $1 device
# $2 name
# $3 output level
led() {
	local dev=$1
	local name=$2
	local output=$3

	echo "$pre: led $dev: $name" > /dev/console
	[ -d /sys/class/leds/$dev ] || {
		echo "$pre: Error: /sys/class/leds/$dev does not exist" > /dev/console
		return
	}
	# allow all users to modify brightness
	chown system.system /sys/class/leds/$dev/brightness
	chmod 0666 /sys/class/leds/$dev/brightness

	echo "$pre: setting $dev/$name to $output" > /dev/console
	[ "$output" ] && echo $output > /sys/class/leds/$dev/brightness

	# set property to map the name to device
	setprop hw.led.$name $dev
}

# get board from cmdline
for x in `cat /proc/cmdline`; do
  [[ $x = androidboot.board=* ]] || continue
  board="${x#androidboot.board=}"
done

# as fallback get from eeprom manually
[ -z "$board" ] && {
	board=`dd if=/sys/bus/i2c/devices/0-0051/eeprom \
		bs=1 count=16 skip=48 2>/dev/null | busybox hexdump -C | \
		busybox head -1 | busybox cut -c62-77 | busybox tr -d .`
}

# determine serialnum from eeprom
s0=$(i2cget -f -y 0 0x51 0x18)
s1=$(i2cget -f -y 0 0x51 0x19)
s2=$(i2cget -f -y 0 0x51 0x1a)
s3=$(i2cget -f -y 0 0x51 0x1b)
serial=$((s0|s1<<8|s2<<16|s3<<24))

pre="${0##*/}"
echo "$pre: Board: ${board}" > /dev/console

orientation=
gps_device=
cvbs_in=
hdmi_in=
case "$board" in
	GW552*)
		# GPIO mappings
		gpio 16 dio0
		gpio 19 dio1
		gpio 17 dio2
		gpio 20 dio3
		;;
	GW54*)
		orientation=0
		gps_device=/dev/ttymxc4
		# GPIO mappings
		gpio 9 dio0
		gpio 19 dio1
		gpio 41 dio2
		gpio 42 dio3
		# CANbus
		gpio 2 can_stby 0
		# Video Capture
		hdmi_in=/dev/video0
		cvbs_in=/dev/video1
		;;
	GW53*)
		orientation=3
		gps_device=/dev/ttymxc4
		# GPIO mappings
		gpio 16 dio0
		gpio 19 dio1
		gpio 17 dio2
		gpio 20 dio3
		# CANbus
		gpio 2 can_stby 0
		# Video Capture
		cvbs_in=/dev/video0
		;;
	GW52*)
		orientation=3
		gps_device=/dev/ttymxc4
		# GPIO mappings
		gpio 16 dio0
		gpio 19 dio1
		gpio 17 dio2
		gpio 20 dio3
		# CANbus
		gpio 9 can_stby 0
		# Video Capture
		cvbs_in=/dev/video0
		;;
	GW51*)
		gps_device=/dev/ttymxc0
		# GPIO mappings
		gpio 16 dio0
		gpio 19 dio1
		gpio 17 dio2
		gpio 20 dio3
		# Video Capture
		cvbs_in=/dev/video0
		;;
	*)
		echo "$pre: unknown board: $board" > /dev/console
		;;
esac

# Camera configuration
# (landscape mode orient is 0, For portrait mode orient is 90)
[ -r "${cvbs_in}" -a -d /sys/bus/i2c/devices/2-0020 ] && {
	status=$(i2cget -f -y 2 0x20 0x10)
	locked=$((status & 0x1))
	state=nosignal
	[ "$locked" -eq 1 ] && {
		standard=$((status & 0x70))
		case "$standard" in
			64) state="PAL";;
			0) state="NTSC";;
		esac
	}
	echo "$pre: cvbs_in:${cvbs} state=${state}" > /dev/console
	#[ "$state" ] || cvbs_in=
	state_cvbs=$state
}
[ -r "${hdmi_in}" -a -d /sys/bus/i2c/devices/2-0048 ] && {
	state=nosignal
	[ -d /sys/bus/i2c/devices/2-0048/state ] && {
		state="$(cat $/sys/bus/i2c/devices/2-0048/state)"
	}
	echo "$pre: hdmi_in:${hdmi_in} state=${state}" > /dev/console
	#[ "$state" = "locked" ] || hdmi_in=
	state_hdmi=$state
}
setprop camera.disable_zsl_mode 1
if [ "${cvbs_in}" -a "${hdmi_in}" ]; then
	echo "Front Camera: ${state_cvbs} Analog In"
	setprop front_camera_name adv7180_decoder
	setprop front_camera_orient 0
	echo "Front Camera: ${state_hdmi} HDMI In"
	setprop back_camera_name tda1997x_video
	setprop back_camera_orient 0
elif [ "${cvbs_in}" ]; then
	echo "Front Camera: ${state_cvbs} Analog In"
	setprop front_camera_name adv7180_decoder
	setprop front_camera_orient 0
	#setprop back_camera_name uvc
elif [ "${hdmi_in}" ]; then
	echo "Front Camera: ${state_hdmi} HDMI In"
	setprop front_camera_name tda1997x_video
	setprop front_camera_orient 0
	#setprop back_camera_name uvc
fi

# Accelerometer/Magnetometer physical orientation
[ "$orientation" -a -d /sys/bus/i2c/devices/2-001e ] && {
	i=0
	while [ 1 ]; do
		[ -d /sys/class/input/input${i} ] || break
		name="$(cat /sys/class/input/input${i}/name)"
		[ "$name" = "FreescaleAccelerometer" ] && {
			echo $orientation \
			  > /sys/devices/virtual/input/input${i}/position
			echo "$pre: Accelerometer input${i} pos$orientation" \
			  > /dev/console
		}
		i=$((i+1))
	done
}

# GPS configuration
gps_present=$(($(i2cget -f -y 0 0x51 0x48) & 0x01))
[ "$gps_present" -a -c "$gps_device" ] && {
	echo "$pre: GPS UART: $gps_device" > /dev/console
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

# initialize CAN bus
gpio=$(getprop gpio.can_stby)
[ "$gpio" -a -d /sys/class/net/can0 ] && {
	echo "$pre: Configuring CANbus" > /dev/console
	ip link set can0 type can $CAN_ARGS
	ifconfig can0 up
}

# bluetooth RFKILL fixup
chmod 666 /sys/class/rfkill/rfkill1/state
echo 1 > /sys/class/bluetooth/hci0/rfkill0/state
# USB perms
chmod -R 777 /dev/bus/usb

# execute user-specifc init script
[ -x /data/bin/init.sh ] && /data/bin/init.sh
