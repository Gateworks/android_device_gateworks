# Copyright (C) 2016 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Emit extra commands needed for Group during OTA installation
(installing the bootloader)."""

import common
import fnmatch

#def InstallRecovery(info):
#  # Copy ramdisk (we use the same bootscript/kernel/dtbs as BOOT)
#  common.ZipWriteStr(info.output_zip, filename, file)
#  info.script.AppendExtra('package_extract_file("BOOTLOADER/SPL", "/SPL");')

def InstallBoot(info):
  # Copy bootscript/kernel/dtbs to output
  for filename in fnmatch.filter(info.input_zip.namelist(), "BOOT/boot/*"):
    file = info.input_zip.read(filename)
    common.ZipWriteStr(info.output_zip, filename, file)

  # Append edify script
  info.script.AppendExtra("""
stdout("Mounting /boot partition\\n");
mount("/boot");
stdout("Deleting /boot partition contents before unpacking OTA BOOT files\\n");
delete_recursive("/boot/boot");
package_extract_dir("BOOT", "/boot");
run_program("/system/bin/sync");
stdout("Finished updating /boot partition, unmounting...\\n");
unmount("/boot");
""")


def InstallBootloader(info):
  # Copy SPL, u-boot.img to output
  for filename in fnmatch.filter(info.input_zip.namelist(), "BOOTLOADER/*"):
    file = info.input_zip.read(filename)
    common.ZipWriteStr(info.output_zip, filename, file)

  # Append edify script
  info.script.AppendExtra("""
stdout("Extract the SPL and u-boot.img from the BOOTLOADER dir\\n");
package_extract_file("BOOTLOADER/SPL", "/SPL");
package_extract_file("BOOTLOADER/u-boot.img", "/u-boot.img");

stdout("Deciding whether or not this is a block or nand flash device\\n");
if getprop(ro.boot.mode) == block then
    stdout("This is a block device. Now decide if this is uSD or eMMC\\n");
    if run_program("/system/bin/ls", "/dev/block/"+getprop(ro.boot.bootdev)+"boot0") == 0 then
        # Board booted from eMMC storage, need to clear force_ro before writing
        file_write("/sys/block/"+getprop(ro.boot.bootdev)+"boot0/"+"force_ro", "0\\n");
        # Erase the bootloader environment (on raw device, not boot0)
        run_program("/system/bin/dd", "if=/dev/zero", "of=/dev/block/"+getprop(ro.boot.bootdev), "bs=1k", "seek=709", "count=256");
        # Flash the SPL
        run_program("/system/bin/dd", "if=/SPL", "of=/dev/block/"+getprop(ro.boot.bootdev)+"boot0", "bs=1k", "seek=1");
        # Flash the bootloader
        run_program("/system/bin/dd", "if=/u-boot.img", "of=/dev/block/"+getprop(ro.boot.bootdev)+"boot0", "bs=1k", "seek=69");
        file_write("/sys/block/"+getprop(ro.boot.bootdev)+"boot0/"+"force_ro", "1\\n");
        # Sync to ensure writes
        run_program("/system/bin/sync");
    else
        # Board has regular uSD storage
        # Erase the bootloader environment
        run_program("/system/bin/dd", "if=/dev/zero", "of=/dev/block/"+getprop(ro.boot.bootdev), "bs=1k", "seek=709", "count=256");
        # Flash the SPL
        run_program("/system/bin/dd", "if=/SPL", "of=/dev/block/"+getprop(ro.boot.bootdev), "bs=1k", "seek=1");
        # Flash the bootloader
        run_program("/system/bin/dd", "if=/u-boot.img", "of=/dev/block/"+getprop(ro.boot.bootdev), "bs=1k", "seek=69");
        # Sync to ensure writes
        run_program("/system/bin/sync");
    endif;
endif;

# Even though there may have been a block boot device, the bootloader could still come
# from flash, so overwrite that as well if it is formatted with our 3 mtd partitions
if run_program("/system/bin/ls", "/dev/mtd/mtd0", "/dev/mtd/mtd1", "/dev/mtd/mtd2") == 0 then
    stdout("This is a flash device\\n");
    run_program("/sbin/kobs-ng", "init", "-v", "-x", "--search_exponent=1", "--chip_0_size=0xe00000", "--chip_0_device_path=/dev/mtd/mtd0", "/SPL");
    run_program("/sbin/flash_erase", "/dev/mtd/mtd0", "0xe00000", "0");
    run_program("/sbin/nandwrite", "--start=0xe00000", "--pad", "/dev/mtd/mtd0", "/u-boot.img");
endif;
stdout("Finished dd'ing the SPL and U-Boot\\n");
""")

def FullOTA_InstallEnd(info):
  info.script.AppendExtra("""stdout("### BEGIN POST OTA EDIFY SCRIPT ###")""")
  InstallBoot(info)
  InstallBootloader(info)
  #InstallRecovery(info)

def IncrementalOTA_InstallBegin(info):
  info.script.Unmount("/system")
  info.script.TunePartition("/system", "-O", "^has_journal")
  info.script.Mount("/system")
