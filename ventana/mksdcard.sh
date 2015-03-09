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

# determine appropriate OUTDIR (where build artifacts are located)
# - can be passed in env via OUTDIR
# - will be out/target/product/$product if dir exists
# - else current dir
if ! [ -d "$OUTDIR" ]; then
   if [ -d out/target/product/$product ]; then
      OUTDIR=out/target/product/$product
   else
      OUTDIR=.
   fi
fi
# verify build artifacts
[ -d "$OUTDIR/boot" ] ||
   { echo "Error: Missing directory: $OUTDIR/boot"; exit 1; }
for i in boot/boot/uImage uramdisk-recovery.img userdata.img system.img; do
   echo checking $OUTDIR/$i
   [ -f "$OUTDIR/$i" ] ||
      { echo "Error: Missing file: $OUTDIR/$i"; exit 1; }
done

# create list of block devices between 3772MB and 61035MB
removable_disks() {
	for f in `ls /dev/disk/by-path/* | grep -v part` ; do
		diskname=$(basename `readlink $f`);
		type=`cat /sys/class/block/$diskname/device/type` ;
		size=`cat /sys/class/block/$diskname/size` ;
		issd=0 ;
		# echo "checking $diskname/$type/$size" ;
		if [ $size -ge 3862528 ]; then
			if [ $size -lt 64500000 ]; then
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

# sanity check - make sure there are not conflicting removable storage
# partitions mounted or left behind from a failed run
[ -e /media/BOOT -o -e /media/RECOVER -o -e /media/DATA ] && {
  echo "Error: content already exists in /media for BOOT/RECOVER/DATA parts"
  echo "either you have a mounted removable storage device with conflicting"
  echo "partition names, or you have files in /media that should not be there"
  ls -l /media
  exit 1
}

dd if=/dev/zero of=${diskname}${prefix} count=1 bs=1024 oflag=sync

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
sudo sfdisk -R ${diskname}${prefix}

mkfs.ext4 -L BOOT ${diskname}${prefix}1
mkfs.ext4 -L RECOVER ${diskname}${prefix}2
mkfs.ext4 -L CACHE ${diskname}${prefix}6
mkfs.ext4 -L VENDOR ${diskname}${prefix}7
mkfs.ext4 -L MISC ${diskname}${prefix}8
sync && sudo sfdisk -R ${diskname}${prefix}

# some slower systems need a sleep here to let the host OS catch up
sync && sleep 10
for n in 1 2 ; do
   udisks --mount ${diskname}${prefix}${n}
done
# sanity check - I'm seeing that occasionally we continue on before the
# partitions are mounted
[ -d /media/BOOT -a -d /media/RECOVER ] || {
  echo "Error: mount not complete!"
  ls -l /media
  exit 1
}

# BOOT: bootscripts, kernel, and ramdisk
mkdir /media/BOOT/boot
sudo cp -rfv $OUTDIR/boot/* /media/BOOT/
# RECOVERY: bootscripts, kernel, and ramdisk-recovery.img
sudo cp -rfv $OUTDIR/boot/boot/uImage /media/RECOVER/
sudo cp -rfv $OUTDIR/uramdisk-recovery.img /media/RECOVER/
# DATA: user data
sudo dd if=$OUTDIR/userdata.img of=${diskname}${prefix}4
sudo e2label ${diskname}${prefix}4 DATA
sudo e2fsck -f ${diskname}${prefix}4
sudo resize2fs ${diskname}${prefix}4
# SYSTEM: system image
sudo dd if=$OUTDIR/system.img of=${diskname}${prefix}5
sudo e2label ${diskname}${prefix}5 SYSTEM
sudo e2fsck -f ${diskname}${prefix}5
sudo resize2fs ${diskname}${prefix}5

sync && sudo umount ${diskname}${prefix}*

