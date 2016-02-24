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
  # Install
  #info.script.FormatPartition("/boot")
  info.script.Mount("/boot")
  info.script.UnpackPackageDir("BOOT", "/boot")

def InstallBootloader(info):
  # Copy SPL, u-boot.img to output
  for filename in fnmatch.filter(info.input_zip.namelist(), "BOOTLOADER/*"):
    file = info.input_zip.read(filename)
    common.ZipWriteStr(info.output_zip, filename, file)
  # Install SPL, u-boot.img, and erase u-boot environment
  info.script.AppendExtra('package_extract_file("BOOTLOADER/SPL", "/SPL");')
  info.script.AppendExtra('package_extract_file("BOOTLOADER/u-boot.img", "/u-boot.img");')
  info.script.AppendExtra('run_program("/sbin/kobs-ng", "init", "-v", "-x", "--search_exponent=1", "--chip_0_size=0xe00000", "--chip_0_device_path=/dev/mtd/mtd0", "/SPL");')
  info.script.AppendExtra('run_program("/sbin/flash_erase", "/dev/mtd/mtd0", "0xe00000", "0");')
  info.script.AppendExtra('run_program("/sbin/nandwrite", "--start=0xe00000", "--pad", "/dev/mtd/mtd0", "/u-boot.img");')
  # Erase bootloader env (if desired)
  #info.script.AppendExtra('run_program("/sbin/flash_erase", "/dev/mtd/mtd1", "0", "0");')

# called on the final stage of recovery:
#   wipe/install system(done for us), boot, and bootloader
def FullOTA_InstallEnd_Ext4(info):
  InstallBoot(info)
  InstallBootloader(info)
  #InstallRecovery(info)

def FullOTA_InstallEnd_Ubifs(info):
  InstallBoot(info)
  InstallBootloader(info)
  #InstallRecovery(info)

def IncrementalOTA_InstallBegin(info):
  info.script.Unmount("/system")
  info.script.TunePartition("/system", "-O", "^has_journal")
  info.script.Mount("/system")
