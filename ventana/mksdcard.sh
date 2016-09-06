#!/bin/bash

product=ventana
verbose=0
bootloader=1
minmb=1500
partoffset=1
#LOG=$(basename $0).log

unset mnt DEV mounts

debug() {
  [ "$verbose" -gt 0 ] && echo "$@"
  echo "DEBUG: $@" >> $LOG
}

cleanup() {
    local ec=$?

    [ -e "${mnt}" ] && {
        printf "Unmounting ${DEV}\n"
        umount ${DEV}? 2>/dev/null
        local uec=$?
        rm -rf ${mnt}
        sync
    }

    [ ${ec} -eq 0 -a ${uec:-0} -eq 0 -a -z "$mounts" ] && \
        printf "You may now safely remove ${BLOCK_DEV}\n"
}

error() {
  [ "$@" ] && echo "Error: $@"
  [ "$LOG" ] && echo "ERROR: $@" >> $LOG
  cleanup
  exit 1
}

trap "cleanup; exit;" SIGINT SIGTERM

# parse cmdline options
while [ "$1" ]; do
  case "$1" in
    --verbose|-v) verbose=$((verbose+1)); [ $verbose -gt 1 ] && LOG=1; shift;;
    *) DEV=$1; shift;;
  esac
done

# verify root
[ $EUID -ne 0 ] && error "must be run as root"

# verify dependencies
for i in ls cat grep mount umount sfdisk sync mkfs.ext4 dd pv cp e2label e2fsck resize2fs rm awk; do
  which $i 2>&1 >/dev/null
  [ $? -eq 1 ] && error "missing '$i' - please install"
done

[ "$DEV" ] || {
  echo ""
  echo "Usage: $(basename 0) [OPTIONS] <blockdev>"
  echo ""
  echo "Options:"
  echo " --force,-f     - force disk"
  echo " --verbose,-v   - increase verbosity"
  exit -1
}

echo "Gateworks Ventana Android disk imaging tool v1.01"
[ "$LOG" ] && { echo "Logging to $LOG"; rm -f $LOG; }
[ "$LOG" ] || LOG=/dev/null

# verify output device
[ -b "$DEV" ] || error "$DEV is not a valid block device"
[ "$minmb" ] && {
  size="$(cat /sys/class/block/$(basename $DEV)/size)"
  size=$((size*512/1000/1000)) # convert to MB (512B blocks)
  debug "$DEV is ${size}MB"
  [ $size -lt $minmb ] && error "$DEV ${size}MB too small - ${minmb}MB required"
}
mounts="$(grep "^$DEV" /proc/mounts | awk '{print $1}')"
[ "$mounts" ] && error "$DEV has mounted partitions: $mounts"

# determine appropriate OUTDIR (where build artifacts are located)
# - can be passed in env via OUTDIR
# - will be out/target/product/$product if dir exists
# - else current dir
[ -d "$OUTDIR" ] || {
  OUTDIR=.
  [ -d out/target/product/$product ] && OUTDIR=out/target/product/$product
}
echo "Installing artifacts from $OUTDIR/"

# verify build artifacts
for i in boot/boot/uImage recovery/boot/uImage userdata.img system.img SPL u-boot.img; do
   debug "  checking file: $OUTDIR/$i"
   [ -f "$OUTDIR/$i" ] || error "Missing file: $OUTDIR/$i"
done

echo "Installing on $DEV..." ;

[ $bootloader ] && {
  echo "Installing bootloader..."

  # SPL (at 1KB offset)
  echo "  installing SPL@1K..."
  dd if=$OUTDIR/SPL of=$DEV bs=1K seek=1 oflag=sync status=none || error

  # UBOOT (at 69K offset)
  echo "  installing UBOOT@69K..."
  dd if=$OUTDIR/u-boot.img of=$DEV bs=1K seek=69 oflag=sync status=none || error

  # ENV (at 709KB offset)
  [ "$UBOOTENV" -a -r "$UBOOTENV" ] && {
    echo "  installing ENV@709K..."
    dd if=$UBOOTENV of=$DEV bs=1K seek=709 oflag=sync status=none || error
  }
  sync || error "sync failed"
}

echo "Partitioning..."
# Partitions:
# 1:BOOT     ext4 20MiB
# 2:RECOVERY ext4 20MiB
# 3:extended partition table
# 4:DATA     ext4 (remainder)
# 5:SYSTEM   ext4 512MiB
# 6:CACHE    ext4 256MiB
# 7:VENDOR   ext4 10MiB
# MiB (M) to sector (S) conversion: S = $((M * 2048))
sfdisk --force --quiet --no-reread -uS $DEV >>$LOG 2>&1 << EOF
$((1 * 2048)),$((20 * 2048)),L,*
$((21 * 2048)),$((20 * 2048)),L
$((41 * 2048)),$((1024 * 2048)),E
$((1065 * 2048)),,L
,$((512 * 2048)),L
,$((256 * 2048)),L
,$((10 * 2048)),L
EOF
[ $? -eq 0 ] || error "sfdisk failed"
sync || error "sync failed"

# sanity-check: verify partitions present
for n in `seq 1 7` ; do
   [ -e ${DEV}$n ] || error "  missing ${DEV}$n"
done
debug "  Partitioning complete"

# Reread the partition table to avoid overwrite prompts
blockdev --rereadpt $DEV 2>/dev/null

echo "Formating partitions..."
mkfs.ext4 -q -F -L BOOT ${DEV}1 1>/dev/null || error "mkfs BOOT"
mkfs.ext4 -q -F -L RECOVER ${DEV}2 1>/dev/null || error "mkfs RECOVER"
mkfs.ext4 -q -F -L CACHE ${DEV}6 1>/dev/null || error "mkfs CACHE"
mkfs.ext4 -q -F -L VENDOR ${DEV}7 1>/dev/null || error "mkfs VENDOR"

mnt=/tmp/$(basename $0).$$
mkdir $mnt
echo "Mounting partitions..."
for n in 1 2 ; do
   mkdir ${mnt}/${n}
   debug "  mounting ${DEV}${n} to ${mnt}/${n}"
   mount -t ext4 ${DEV}${n} ${mnt}/${n} || error "mount ${DEV}${n}"
done

# BOOT: bootscripts, kernel, and ramdisk
echo "Writing BOOT partition..."
cp -rfv $OUTDIR/boot/* ${mnt}/1 >>$LOG || error
sync && umount ${DEV}1 || error "failed umount"

# RECOVERY: bootscripts, kernel, and ramdisk-recovery.img
echo "Writing RECOVERY partition..."
cp -rfv $OUTDIR/recovery/boot/* ${mnt}/2 >>$LOG || error
sync && umount ${DEV}2 || error "failed umount"

# DATA: user data
echo "Writing DATA partition..."
pv -petr $OUTDIR/userdata.img | dd of=${DEV}4 bs=4M oflag=sync status=none \
  || error "dd"
e2label ${DEV}4 DATA || error "e2label failed"
e2fsck -y -f ${DEV}4 >>$LOG 2>&1 || error "e2fsck failed"
resize2fs ${DEV}4 >>$LOG 2>&1 || error "resize2fs failed"
sync

# SYSTEM: system image
echo "Writing SYSTEM partition..."
pv -petr $OUTDIR/system.img | dd of=${DEV}5 bs=4M oflag=sync status=none \
  || error "dd"
e2label ${DEV}5 SYSTEM || error "e2label failed"
e2fsck -y -f ${DEV}5 >>$LOG 2>&1 || error "e2fsck failed"
resize2fs ${DEV}5 >>$LOG 2>&1 || error "resize2fs failed"
sync

cleanup
