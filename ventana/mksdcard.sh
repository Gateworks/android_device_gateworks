#!/bin/bash
if [ $# -lt 1 ]; then
	echo "Usage: $0 /dev/diskname [product=ventana] [--force]"
	exit -1 ;
fi

force='';
if [ $# -ge 2 ]; then
   product=$2;
   if [ $# -ge 3 ]; then
      if [ "x--force" == "x$3" ]; then
         force=yes;
      fi
   fi
else
   product=ventana;
fi

echo "---------build SD card for product $product";

if ! [ -d out/target/product/$product/data ]; then
   echo "Missing out/target/product/$product";
   exit 1;
fi

removable_disks() {
	for f in `ls /dev/disk/by-path/* | grep -v part` ; do
		diskname=$(basename `readlink $f`);
		type=`cat /sys/class/block/$diskname/device/type` ;
		size=`cat /sys/class/block/$diskname/size` ;
		issd=0 ;
		# echo "checking $diskname/$type/$size" ;
		if [ $size -ge 3862528 ]; then
			if [ $size -lt 62500000 ]; then
				issd=1 ;
			fi
		fi
		if [ "$issd" -eq "1" ]; then
			echo -n "/dev/$diskname ";
			# echo "removable disk /dev/$diskname, size $size, type $type" ;
			#echo -n -e "\tremovable? " ; cat /sys/class/block/$diskname/removable ;
		fi
	done
	echo;
}
diskname=$1
removables=`removable_disks`

for disk in $removables ; do
   echo "removable disk $disk" ;
   if [ "$diskname" = "$disk" ]; then
      matched=1 ;
      break ;
   fi
done

if [ -z "$matched" -a -z "$force" ]; then
   echo "Invalid disk $diskname" ;
   exit -1;
fi

prefix='';

if [[ "$diskname" =~ "mmcblk" ]]; then
   prefix=p
fi

echo "reasonable disk $diskname, partitions ${diskname}${prefix}1..." ;
umount ${diskname}${prefix}*
umount gvfs

dd if=/dev/zero of=${diskname}${prefix} count=1 bs=1024

# Partitions:
# 1:BOOT     ext4 20MB
# 2:RECOVERY ext4 20MB
# 3:extended partition table
# 4:DATA     ext4 (remainder)
# 5:SYSTEM   ext4 512MB
# 6:CACHE    ext4 512MB
# 7:VENDOR   ext4 10MB
# 8:MISC     ext4 10MB
sudo sfdisk --force -uM ${diskname}${prefix} << EOF
,20,83,*
,20,83
,1024,E
,,83
,512,83
,50,83
,10,83
,10,83
EOF

for n in `seq 1 8` ; do
   if ! [ -e ${diskname}${prefix}$n ] ; then
      echo "--------------missing ${diskname}${prefix}$n" ;
      exit 1;
   fi
   sync
done

echo "all partitions present and accounted for!";
sync && sudo sfdisk -R ${diskname}${prefix}

mkfs.ext4 -L BOOT ${diskname}${prefix}1
mkfs.ext4 -L RECOVER ${diskname}${prefix}2
mkfs.ext4 -L DATA ${diskname}${prefix}4
mkfs.ext4 -L CACHE ${diskname}${prefix}6
mkfs.ext4 -L VENDOR ${diskname}${prefix}7
mkfs.ext4 -L MISC ${diskname}${prefix}8

# some slower systems need a sleep here to let the host OS catch up
sleep 10
for n in 1 2 4 ; do
   udisks --mount ${diskname}${prefix}${n}
done

# BOOT: bootscripts, kernel, and ramdisk
mkdir /media/BOOT/boot
sudo cp -rfv out/target/product/$product/boot/* /media/BOOT/
# RECOVER: bootscripts, kernel, and ramdisk-recovery.img
sudo cp -rfv out/target/product/$product/uImage /media/RECOVER/
sudo cp -rfv out/target/product/$product/uramdisk-recovery.img /media/RECOVER/
# DATA: application data
sudo cp -ravf out/target/product/$product/data/* /media/DATA/
# SYSTEM: system image
sudo dd if=out/target/product/$product/system.img of=${diskname}${prefix}5
sudo e2label ${diskname}${prefix}5 SYSTEM
sudo e2fsck -f ${diskname}${prefix}5
sudo resize2fs ${diskname}${prefix}5

sync && sudo umount ${diskname}${prefix}*

